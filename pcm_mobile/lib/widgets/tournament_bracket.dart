import 'package:flutter/material.dart';
import '../models/tournament_models.dart';
import '../themes/app_colors.dart';

class TournamentBracket extends StatelessWidget {
  final TournamentDetailModel tournament;
  final List<MatchModel> matches;

  const TournamentBracket({
    super.key,
    required this.tournament,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Chưa có trận đấu nào\n\nAdmin cần tạo lịch thi đấu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Group matches by round
    final Map<String, List<MatchModel>> matchesByRound = {};
    for (var match in matches) {
      final round = match.roundName ?? 'Unknown';
      if (!matchesByRound.containsKey(round)) {
        matchesByRound[round] = [];
      }
      matchesByRound[round]!.add(match);
    }

    // Determine if knockout format
    final isKnockout = tournament.format == 'Knockout' || tournament.format == 'Hybrid';

    if (isKnockout && matchesByRound.length > 1) {
      return _buildKnockoutBracket(matchesByRound);
    } else {
      return _buildListView(matchesByRound);
    }
  }

  Widget _buildKnockoutBracket(Map<String, List<MatchModel>> matchesByRound) {
    // Order rounds: Final, Semi-Final, Quarter-Final, R16, etc.
    final orderedRounds = _orderKnockoutRounds(matchesByRound.keys.toList());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: orderedRounds.reversed.map((round) {
            final roundMatches = matchesByRound[round]!;
            return _buildRoundColumn(round, roundMatches, orderedRounds);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundColumn(
    String roundName,
    List<MatchModel> matches,
    List<String> allRounds,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Round Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoundDisplayName(roundName),
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Matches
          ...matches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 24),
                _buildMatchCard(match, roundName, allRounds),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, String currentRound, List<String> allRounds) {
    final team1Name = match.team1Player1Name ?? 'TBD';
    final team2Name = match.team2Player1Name ?? 'TBD';
    final score1 = match.score1 ?? 0;
    final score2 = match.score2 ?? 0;
    final isFinished = match.status == 'Finished';
final winningSide = match.winningSide;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinished ? AppColors.primary.withOpacity(0.3) : AppColors.cream,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Team 1
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: winningSide == 'Team1' 
                  ? AppColors.primary.withOpacity(0.15) 
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                if (winningSide == 'Team1')
                  Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
                if (winningSide == 'Team1') const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team1Name,
                    style: TextStyle(
                      fontWeight: winningSide == 'Team1' 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFinished)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: winningSide == 'Team1' 
                          ? AppColors.primary 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      score1.toString(),
                      style: TextStyle(
                        color: winningSide == 'Team1' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Team 2
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: winningSide == 'Team2' 
                  ? AppColors.primary.withOpacity(0.15) 
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Row(
              children: [
                if (winningSide == 'Team2')
                  Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
                if (winningSide == 'Team2') const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team2Name,
                    style: TextStyle(
                      fontWeight: winningSide == 'Team2' 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFinished)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: winningSide == 'Team2' 
                          ? AppColors.primary 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      score2.toString(),
                      style: TextStyle(
                        color: winningSide == 'Team2' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Match info
          if (match.date != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    match.date ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView(Map<String, List<MatchModel>> matchesByRound) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: matchesByRound.entries.map((entry) {
        final round = entry.key;
        final matches = entry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _getRoundDisplayName(round),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            ...matches.map((match) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.sports,
                  color: match.status == 'Finished' 
                      ? AppColors.success 
                      : AppColors.accent,
                ),
                title: Text(
                  '${match.team1Player1Name ?? 'TBD'} vs ${match.team2Player1Name ?? 'TBD'}',
                ),
                subtitle: Text(match.date ?? 'Chưa có lịch'),
                trailing: match.status == 'Finished'
                    ? Text(
                        '${match.score1}-${match.score2}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      )
                    : Text(
                        match.status ?? 'Scheduled',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
              ),
            )),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  List<String> _orderKnockoutRounds(List<String> rounds) {
    final order = {
      'Final': 5,
      'Semi-Final': 4,
      'Semifinal': 4,
      'Quarter-Final': 3,
      'Quarterfinal': 3,
      'Round of 16': 2,
      'R16': 2,
      'Round of 32': 1,
      'R32': 1,
    };

    rounds.sort((a, b) {
      final aOrder = order[a] ?? 0;
      final bOrder = order[b] ?? 0;
      return aOrder.compareTo(bOrder);
    });

    return rounds;
  }

  String _getRoundDisplayName(String round) {
    final map = {
      'Final': 'Chung kết',
      'Semi-Final': 'Bán kết',
      'Semifinal': 'Bán kết',
      'Quarter-Final': 'Tứ kết',
      'Quarterfinal': 'Tứ kết',
      'Round of 16': 'Vòng 1/16',
      'R16': 'Vòng 1/16',
      'Round of 32': 'Vòng 1/32',
      'R32': 'Vòng 1/32',
    };
    
    return map[round] ?? round;
  }
}
