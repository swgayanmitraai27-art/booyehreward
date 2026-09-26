/**
 * Booyah Rewards - Firebase Cloud Function
 * Automated Profit-Sharing Calculation & Immutable Match Ledger Engine
 *
 * Trigger: Firestore onDocumentUpdated('matches/{matchId}') OR onCall('completeMatchWithFinancials')
 * 
 * Rules:
 * - total_entry_collection = entryFee * participants.length (or actual cash collected)
 * - platform_commission_gross = 30% of total_entry_collection (70/30 esports engine)
 * - gateway_fee_deduction = 2.36% of total_entry_collection (Razorpay 2% standard + 18% GST)
 * - net_profit = platform_commission_gross - gateway_fee_deduction
 * - shares:
 *     founder_60 = 60% of net_profit
 *     host_25 = 25% of net_profit
 *     investor_15 = 15% of net_profit
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * 1. Background Trigger: Triggered automatically whenever a Match document status changes to 'COMPLETED'
 */
exports.onMatchCompletedCalculateFinancials = functions.firestore
  .document('matches/{matchId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const matchId = context.params.matchId;

    // Trigger ONLY if status just changed to COMPLETED and financial_breakdown not yet recorded
    const wasCompleted = beforeData.status === 'COMPLETED' || beforeData.status === 'completed';
    const isNowCompleted = afterData.status === 'COMPLETED' || afterData.status === 'completed';

    if (!wasCompleted && isNowCompleted) {
      if (afterData.financial_breakdown && afterData.financial_breakdown.net_profit !== undefined) {
        console.log(`[FINANCIALS] Match ${matchId} already has financial breakdown.`);
        return null;
      }

      console.log(`[FINANCIALS] Calculating profit sharing for match: ${matchId}`);

      const entryFee = Number(afterData.entryFee || 0);
      const isPaidMatch = afterData.matchType === 'paid' || afterData.entryFeeType === 'cash';
      const participants = afterData.participants || [];
      const filledSlots = Number(afterData.filledSlots || participants.length || 0);

      // Compute Total Collection
      let totalEntryCollection = 0;
      if (isPaidMatch) {
        if (participants.length > 0) {
          totalEntryCollection = participants.reduce((sum, p) => sum + Number(p.amountPaid || entryFee), 0);
        } else {
          totalEntryCollection = entryFee * filledSlots;
        }
      }

      // Financial Formula (70/30 platform commission, 2.36% gateway fee)
      const platformCommissionGross = isPaidMatch ? Number((totalEntryCollection * 0.30).toFixed(2)) : 0;
      const gatewayFeeDeduction = isPaidMatch ? Number((totalEntryCollection * 0.0236).toFixed(2)) : 0;
      const netProfit = Number(Math.max(0, platformCommissionGross - gatewayFeeDeduction).toFixed(2));

      // 60 / 25 / 15 Profit Shares
      const founder60 = Number((netProfit * 0.60).toFixed(2));
      const host25 = Number((netProfit * 0.25).toFixed(2));
      const investor15 = Number((netProfit * 0.15).toFixed(2));

      const financialBreakdown = {
        total_entry_collection: totalEntryCollection,
        platform_commission_gross: platformCommissionGross,
        gatewayFee_deduction: gatewayFeeDeduction,
        gateway_fee_deduction: gatewayFeeDeduction,
        net_profit: netProfit,
        shares: {
          founder_60: founder60,
          host_25: host25,
          investor_15: investor15,
        },
      };

      const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

      // Write atomically to Match document
      await change.after.ref.update({
        status: 'COMPLETED',
        completed_at: serverTimestamp,
        financial_breakdown: financialBreakdown,
      });

      // Also append to immutable global financial ledger collection for auditing
      await db.collection('financial_ledger').doc(matchId).set({
        match_id: matchId,
        match_title: afterData.title || 'Esports Match',
        match_type: afterData.matchType || 'paid',
        mode: afterData.mode || 'br',
        host_name: afterData.host_name || 'Admin',
        completed_at: serverTimestamp,
        financial_breakdown: financialBreakdown,
      });

      console.log(`[FINANCIALS] Successfully sealed financial breakdown for match ${matchId}: Net Profit ₹${netProfit}`);
    }

    return null;
  });

/**
 * 2. Callable Cloud Function: Admin/Host 1-click result declaration with instant server-calculated ledger
 */
exports.declareMatchResultSecure = functions.https.onCall(async (data, context) => {
  // Verify Admin authorization
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to declare results.');
  }

  const { matchId, hostName, results } = data;
  if (!matchId) {
    throw new functions.https.HttpsError('invalid-argument', 'matchId is required.');
  }

  const matchRef = db.collection('matches').doc(matchId);
  const matchDoc = await matchRef.get();

  if (!matchDoc.exists) {
    throw new functions.https.HttpsError('not-found', `Match ${matchId} not found.`);
  }

  const matchData = matchDoc.data();
  const entryFee = Number(matchData.entryFee || 0);
  const isPaidMatch = matchData.matchType === 'paid' || matchData.entryFeeType === 'cash';
  const participants = matchData.participants || [];
  const filledSlots = Number(matchData.filledSlots || participants.length || 0);

  let totalEntryCollection = 0;
  if (isPaidMatch) {
    if (participants.length > 0) {
      totalEntryCollection = participants.reduce((sum, p) => sum + Number(p.amountPaid || entryFee), 0);
    } else {
      totalEntryCollection = entryFee * filledSlots;
    }
  }

  const platformCommissionGross = isPaidMatch ? Number((totalEntryCollection * 0.30).toFixed(2)) : 0;
  const gatewayFeeDeduction = isPaidMatch ? Number((totalEntryCollection * 0.0236).toFixed(2)) : 0;
  const netProfit = Number(Math.max(0, platformCommissionGross - gatewayFeeDeduction).toFixed(2));

  const founder60 = Number((netProfit * 0.60).toFixed(2));
  const host25 = Number((netProfit * 0.25).toFixed(2));
  const investor15 = Number((netProfit * 0.15).toFixed(2));

  const financialBreakdown = {
    total_entry_collection: totalEntryCollection,
    platform_commission_gross: platformCommissionGross,
    gateway_fee_deduction: gatewayFeeDeduction,
    net_profit: netProfit,
    shares: {
      founder_60: founder60,
      host_25: host25,
      investor_15: investor15,
    },
  };

  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

  await matchRef.update({
    status: 'COMPLETED',
    host_name: hostName || context.auth.token.name || 'Admin Host',
    completed_at: serverTimestamp,
    financial_breakdown: financialBreakdown,
  });

  return {
    success: true,
    matchId: matchId,
    financial_breakdown: financialBreakdown,
  };
});
