import 'package:flutter/material.dart';
import 'package:kisan_veer/models/user_model.dart';

class CommunityMembersModal extends StatelessWidget {
  final List<UserModel> members;

  const CommunityMembersModal({Key? key, required this.members})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Text(
            "Community Members",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: members[index].photoUrl != null
                        ? NetworkImage(members[index].photoUrl!)
                        : null,
                    child: members[index].photoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    members[index].name,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
