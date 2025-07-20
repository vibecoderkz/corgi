import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedPeriod = 'This Week';
  
  final List<LeaderboardEntry> leaderboardData = [
    LeaderboardEntry(
      rank: 1,
      name: 'Alex Johnson',
      points: 2450,
      avatar: 'AJ',
      change: 2,
      isCurrentUser: false,
    ),
    LeaderboardEntry(
      rank: 2,
      name: 'Sarah Williams',
      points: 2380,
      avatar: 'SW',
      change: -1,
      isCurrentUser: false,
    ),
    LeaderboardEntry(
      rank: 3,
      name: 'Mike Chen',
      points: 2290,
      avatar: 'MC',
      change: 1,
      isCurrentUser: false,
    ),
    LeaderboardEntry(
      rank: 4,
      name: 'You',
      points: 2150,
      avatar: 'ME',
      change: 3,
      isCurrentUser: true,
    ),
    LeaderboardEntry(
      rank: 5,
      name: 'Emma Davis',
      points: 2100,
      avatar: 'ED',
      change: -2,
      isCurrentUser: false,
    ),
    LeaderboardEntry(
      rank: 6,
      name: 'David Kim',
      points: 2050,
      avatar: 'DK',
      change: 0,
      isCurrentUser: false,
    ),
    LeaderboardEntry(
      rank: 7,
      name: 'Lisa Anderson',
      points: 1980,
      avatar: 'LA',
      change: -1,
      isCurrentUser: false,
    ),
    LeaderboardEntry(
      rank: 8,
      name: 'Tom Wilson',
      points: 1920,
      avatar: 'TW',
      change: 2,
      isCurrentUser: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildTopThree(),
          _buildMyRankCard(),
          Expanded(
            child: _buildLeaderboardList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'All Time'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: periods.map((period) {
            final isSelected = selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedPeriod = period;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopThree() {
    final topThree = leaderboardData.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1) _buildPodiumPlace(topThree[1], 2, 80),
          if (topThree.isNotEmpty) _buildPodiumPlace(topThree[0], 1, 100),
          if (topThree.length > 2) _buildPodiumPlace(topThree[2], 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place, double height) {
    Color medalColor;
    switch (place) {
      case 1:
        medalColor = Colors.amber;
        break;
      case 2:
        medalColor = Colors.grey[400]!;
        break;
      case 3:
        medalColor = Colors.brown[300]!;
        break;
      default:
        medalColor = Colors.grey;
    }

    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              CircleAvatar(
                radius: place == 1 ? 40 : 35,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  entry.avatar,
                  style: TextStyle(
                    fontSize: place == 1 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    place.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: place == 1 ? FontWeight.bold : FontWeight.normal,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${entry.points} pts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: medalColor.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                place.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard() {
    final myEntry = leaderboardData.firstWhere((entry) => entry.isCurrentUser);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  myEntry.avatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      myEntry.rank.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            'Your Rank',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text('${myEntry.points} points'),
          trailing: _buildChangeIndicator(myEntry.change),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: leaderboardData.length,
      itemBuilder: (context, index) {
        final entry = leaderboardData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  backgroundColor: entry.isCurrentUser
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  child: Text(
                    entry.avatar,
                    style: TextStyle(
                      color: entry.isCurrentUser ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      entry.rank.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              entry.name,
              style: TextStyle(
                fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('${entry.points} points'),
            trailing: _buildChangeIndicator(entry.change),
          ),
        );
      },
    );
  }

  Widget _buildChangeIndicator(int change) {
    if (change == 0) {
      return const Icon(Icons.remove, color: Colors.grey);
    }
    
    final isPositive = change > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: isPositive ? Colors.green : Colors.red,
          size: 16,
        ),
        Text(
          change.abs().toString(),
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final String avatar;
  final int change;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.avatar,
    required this.change,
    required this.isCurrentUser,
  });
}