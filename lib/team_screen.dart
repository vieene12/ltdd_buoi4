import 'package:flutter/material.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  // Thay nội dung danh sách này bằng thông tin thật của nhóm.
  static const List<TeamMember> _members = <TeamMember>[
    TeamMember(
      name: 'Mai Hà Thanh Vy',
      studentId: 'MSSV: 2380602613',
      role: 'Thành viên',
      email: 'Email: maivy0822@gmail.com',
      imageAsset: 'assets/team/cat_1.jpg',
    ),
    TeamMember(
      name: 'Lê Quang Huy',
      studentId: 'MSSV: 2380600643',
      role: 'Thành viên',
      email: 'Email: lequanghuy@gmail.com',
      imageAsset: 'assets/team/cat_2.jpg',
    ),
    TeamMember(
      name: 'Đoàn Trung Hiếu',
      studentId: 'MSSV: 2380600643',
      role: 'Thành viên',
      email: 'Email: doantrunghieu@gmail.com',
      imageAsset: 'assets/team/cat_3.jpg',
    ),
    TeamMember(
      name: 'Nguyễn Minh Tuấn',
      studentId: 'MSSV: 2380600643',
      role: 'Thành viên',
      email: 'Email: nguyenminhtuan@gmail.com',
      imageAsset: 'assets/team/cat_4.jpg',
    ),
  ];

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin nhóm')),
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Vuốt sang trái hoặc phải để xem từng thành viên'),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: _members.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => _MemberCard(
                member: _members[index],
                position: index + 1,
                total: _members.length,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                _members.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.position,
    required this.total,
  });

  final TeamMember member;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  member.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFE3F2FD),
                    child: Center(child: Icon(Icons.person, size: 120)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    member.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(member.studentId),
                  Text(member.role),
                  Text(member.email),
                  const SizedBox(height: 8),
                  Text('$position / $total'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.name,
    required this.studentId,
    required this.role,
    required this.email,
    required this.imageAsset,
  });

  final String name;
  final String studentId;
  final String role;
  final String email;
  final String imageAsset;
}
