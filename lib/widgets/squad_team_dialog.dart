import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'deposit_dialog.dart';
import 'match_rules_card.dart';

class SquadTeamDialog extends StatefulWidget {
  final MatchModel match;
  final AppState appState;
  final VoidCallback onEarnCoinsClick;

  const SquadTeamDialog({
    super.key,
    required this.match,
    required this.appState,
    required this.onEarnCoinsClick,
  });

  @override
  State<SquadTeamDialog> createState() => _SquadTeamDialogState();
}

class _SquadTeamDialogState extends State<SquadTeamDialog> {
  int activeTab = 0; // 0: Choose Mode, 1: Create Team, 2: Join with Code, 3: Live Team Lobby

  final TextEditingController _teamNameController = TextEditingController(text: '🔥 Squad Alpha');
  final TextEditingController _teamCodeController = TextEditingController();
  final TextEditingController _ignController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  RegisteredTeam? currentTeam;
  String? errorText;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _ignController.text = widget.appState.user.inGameName ?? '';
    _uidController.text = widget.appState.user.inGameUid ?? '';
    _levelController.text = widget.appState.user.inGameLevel.toString();

    // Check if user already in a team for this match
    final existingTeam = widget.match.getTeamForUser(widget.appState.user.uid);
    if (existingTeam != null) {
      currentTeam = existingTeam;
      activeTab = 3; // Go straight to lobby
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamCodeController.dispose();
    _ignController.dispose();
    _uidController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: const Color(0xFF065F46), content: Text('$label copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isFree = match.matchType == MatchType.free;
    final teamSize = match.teamSize;
    final fee = match.entryFee;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFree ? AppTheme.primaryAmber : AppTheme.winningGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      match.teamType == TeamType.squad ? '🛡️' : '👥',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${match.teamType.name.toUpperCase()} TEAM MANAGEMENT',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 1.2),
                        ),
                        Text(
                          '${match.title} ($teamSize Players/Team)',
                          style: AppTheme.gamingTitle(fontSize: 16, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Expanded(child: Text(errorText!, style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ],

                    if (activeTab == 0) _buildInitialChoice(match, isFree, fee, teamSize),
                    if (activeTab == 1) _buildCreateTeamView(match, isFree, fee, teamSize),
                    if (activeTab == 2) _buildJoinTeamView(match, isFree, fee, teamSize),
                    if (activeTab == 3) _buildTeamLobbyView(match, isFree, teamSize),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 0: CHOOSE [CREATE TEAM] OR [JOIN WITH CODE] ---
  Widget _buildInitialChoice(MatchModel match, bool isFree, double fee, int teamSize) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MATCH ENTRY FEE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    isFree ? '🟡 ${fee.toInt()} Ad Coins' : '₹${fee.toInt()} Real Cash',
                    style: AppTheme.gamingNumber(fontSize: 18, color: isFree ? const Color(0xFFB45309) : const Color(0xFF047857)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFree ? Colors.amber.shade100 : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$teamSize Players/Team',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isFree ? Colors.amber.shade900 : const Color(0xFF065F46)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // OPTION 1: CREATE A NEW TEAM (CAPTAIN)
        InkWell(
          onTap: () => setState(() => activeTab = 1),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_moderator, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CREATE A TEAM (CAPTAIN)', style: AppTheme.gamingTitle(fontSize: 14, color: Colors.white, isItalic: false)),
                      const SizedBox(height: 2),
                      Text(
                        'Pay entry fee, generate 6-char Team Code & invite your friends.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // OPTION 2: JOIN WITH TEAM CODE
        InkWell(
          onTap: () => setState(() => activeTab = 2),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.key, color: Color(0xFF0F172A), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('JOIN WITH TEAM CODE', style: AppTheme.gamingTitle(fontSize: 14, color: const Color(0xFF0F172A), isItalic: false)),
                      const SizedBox(height: 2),
                      Text(
                        'Have a 6-digit code from your Captain? Enter it to join their squad.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Official Match Rules Card
        const MatchRulesCard(initiallyExpanded: false),
      ],
    );
  }

  // --- STEP 1: CREATE TEAM FORM ---
  Widget _buildCreateTeamView(MatchModel match, bool isFree, double fee, int teamSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: () => setState(() => activeTab = 0),
            ),
            Text('Create New ${match.teamType.name.toUpperCase()} Team', style: AppTheme.gamingTitle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _teamNameController,
          decoration: InputDecoration(
            labelText: 'Team / Squad Name',
            hintText: 'e.g. 🔥 GodLevel Esports',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _ignController,
          decoration: InputDecoration(
            labelText: 'Free Fire In-Game Name (IGN)*',
            hintText: 'e.g. ꧁★CAPTAIN★꧂',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _uidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Free Fire UID (Numeric)*',
                  hintText: 'e.g. 294819284',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _levelController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'FF ID Level (40+)*',
                  hintText: 'e.g. 52',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entry Fee to Deduct:',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
              ),
              Text(
                isFree ? '🟡 ${fee.toInt()} Ad Coins' : '₹${fee.toInt()} Cash',
                style: AppTheme.gamingNumber(fontSize: 14, color: const Color(0xFF047857)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isSubmitting
                ? null
                : () {
                    final ign = _ignController.text.trim();
                    final ffUid = _uidController.text.trim();
                    final teamName = _teamNameController.text.trim();
                    final levelStr = _levelController.text.trim();
                    final level = int.tryParse(levelStr);

                    if (ign.isEmpty) {
                      setState(() => errorText = 'Free Fire In-Game Name (IGN) daalna mandatory hai.');
                      return;
                    }
                    if (ffUid.isEmpty || ffUid.length < 6 || int.tryParse(ffUid) == null) {
                      setState(() => errorText = 'Valid numeric Free Fire UID daalna mandatory hai (min 6 digits).');
                      return;
                    }
                    if (level == null || level < 40) {
                      setState(() => errorText = 'Anti-Hack Rule: Aapki Free Fire ID ka level minimum 40+ hona compulsory hai (Aapka Level: ${levelStr.isEmpty ? '0' : levelStr}).');
                      return;
                    }

                    // Auto-Save updated IGN, UID & FF Level to profile
                    widget.appState.updateUserProfile(
                      inGameName: ign,
                      inGameUid: ffUid,
                      inGameLevel: level,
                    );

                    setState(() {
                      isSubmitting = true;
                      errorText = null;
                    });

                    final res = widget.appState.createSquadTeam(
                      matchId: match.id,
                      teamName: teamName,
                      inGameName: ign,
                      inGameUid: ffUid,
                    );

                    setState(() => isSubmitting = false);

                    if (res['success'] == true) {
                      setState(() {
                        currentTeam = res['team'] as RegisteredTeam;
                        activeTab = 3; // Go to Team Lobby
                      });
                    } else {
                      setState(() => errorText = res['message']);
                      if (res['message'].toString().contains('Insufficient Cash')) {
                        showDialog(
                          context: context,
                          builder: (c) => DepositDialog(appState: widget.appState),
                        );
                      }
                    }
                  },
            child: isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('CONFIRM & GENERATE TEAM CODE', style: AppTheme.gamingTitle(fontSize: 12, color: Colors.white, isItalic: false)),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: JOIN TEAM WITH CODE ---
  Widget _buildJoinTeamView(MatchModel match, bool isFree, double fee, int teamSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: () => setState(() => activeTab = 0),
            ),
            Text('Enter Captain\'s Team Code', style: AppTheme.gamingTitle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _teamCodeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
          decoration: InputDecoration(
            labelText: '6-Digit Team Code',
            hintText: 'e.g. BYH842',
            prefixIcon: const Icon(Icons.key, color: Colors.amber),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _ignController,
          decoration: InputDecoration(
            labelText: 'Free Fire In-Game Name (IGN)*',
            hintText: 'e.g. ꧁★PLAYER★꧂',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _uidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Free Fire UID (Numeric)*',
                  hintText: 'e.g. 294819284',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _levelController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'FF ID Level (40+)*',
                  hintText: 'e.g. 52',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Entry Fee to Deduct:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
              Text(
                isFree ? '🟡 ${fee.toInt()} Ad Coins' : '₹${fee.toInt()} Cash',
                style: AppTheme.gamingNumber(fontSize: 14, color: const Color(0xFF047857)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isSubmitting
                ? null
                : () {
                    final code = _teamCodeController.text.trim();
                    final ign = _ignController.text.trim();
                    final ffUid = _uidController.text.trim();
                    final levelStr = _levelController.text.trim();
                    final level = int.tryParse(levelStr);

                    if (code.isEmpty) {
                      setState(() => errorText = '6-Digit Team Code daalna zaroori hai.');
                      return;
                    }
                    if (ign.isEmpty) {
                      setState(() => errorText = 'Free Fire In-Game Name (IGN) daalna mandatory hai.');
                      return;
                    }
                    if (ffUid.isEmpty || ffUid.length < 6 || int.tryParse(ffUid) == null) {
                      setState(() => errorText = 'Valid numeric Free Fire UID daalna mandatory hai (min 6 digits).');
                      return;
                    }
                    if (level == null || level < 40) {
                      setState(() => errorText = 'Anti-Hack Rule: Aapki Free Fire ID ka level minimum 40+ hona compulsory hai (Aapka Level: ${levelStr.isEmpty ? '0' : levelStr}).');
                      return;
                    }

                    // Auto-Save updated IGN, UID & FF Level to profile
                    widget.appState.updateUserProfile(
                      inGameName: ign,
                      inGameUid: ffUid,
                      inGameLevel: level,
                    );

                    setState(() {
                      isSubmitting = true;
                      errorText = null;
                    });

                    final res = widget.appState.joinSquadTeamWithCode(
                      matchId: match.id,
                      teamCode: code,
                      inGameName: ign,
                      inGameUid: ffUid,
                    );

                    setState(() => isSubmitting = false);

                    if (res['success'] == true) {
                      setState(() {
                        currentTeam = res['team'] as RegisteredTeam;
                        activeTab = 3; // Go to Team Lobby
                      });
                    } else {
                      setState(() => errorText = res['message']);
                      if (res['message'].toString().contains('Insufficient Cash')) {
                        showDialog(
                          context: context,
                          builder: (c) => DepositDialog(appState: widget.appState),
                        );
                      }
                    }
                  },
            child: isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('VERIFY CODE & JOIN TEAM', style: AppTheme.gamingTitle(fontSize: 12, color: Colors.white, isItalic: false)),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: LIVE TEAM LOBBY (SHARE CODE & ROSTER) ---
  Widget _buildTeamLobbyView(MatchModel match, bool isFree, int teamSize) {
    final team = currentTeam ?? match.getTeamForUser(widget.appState.user.uid);
    if (team == null) {
      return const Center(child: Text('Team data not found.'));
    }

    final isCaptain = team.captainUid == widget.appState.user.uid;
    final remaining = team.slotsRemaining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Code Banner Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    team.teamName.toUpperCase(),
                    style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  if (isCaptain) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('YOU ARE CAPTAIN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    team.teamCode,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber, size: 22),
                    onPressed: () => _copy(team.teamCode, 'Team Code'),
                    tooltip: 'Copy Team Code',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                remaining > 0
                    ? 'Share this code with $remaining friends to join your squad!'
                    : '🎉 Team is COMPLETE (${team.members.length}/$teamSize Players)!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: remaining > 0 ? const Color(0xFF94A3B8) : const Color(0xFF34D399),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Team Roster
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SQUAD ROSTER (${team.members.length}/$teamSize)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: team.isComplete ? const Color(0xFFECFDF5) : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                team.isComplete ? 'READY FOR MATCH' : 'WAITING FOR MEMBERS',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: team.isComplete ? const Color(0xFF047857) : Colors.amber.shade900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Members list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: teamSize,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            if (index < team.members.length) {
              final member = team.members[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: member.isCaptain ? Colors.amber : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.isCaptain ? '👑 CAPTAIN' : 'SLOT #${member.slotNumber}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: member.isCaptain ? Colors.black : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.inGameName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('UID: ${member.inGameUid}', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Color(0xFF047857), size: 16),
                  ],
                ),
              );
            } else {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text('Empty Slot ${index + 1} (Waiting for code join...)', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('DONE / GO TO MY MATCHES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
