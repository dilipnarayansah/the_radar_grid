import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_radar_grid/models/listing.dart';

// ---------------- TAB 4: PROFILE SCREEN ----------------
class ProfileScreen extends StatefulWidget {
  final User? user;
  final List<GridListing> listings;
  final VoidCallback onAuthChanged;

  const ProfileScreen({super.key, required this.user, required this.listings, required this.onAuthChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openAuthDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isSignUp = false;
    String? authError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF10141C),
          title: Text(isSignUp ? '📝 Spot Enterprise Sign Up' : '🔐 Spot Enterprise Sign In', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: const Color(0xFF080B10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: const Color(0xFF080B10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              if (authError != null) ...[
                const SizedBox(height: 8),
                Text(authError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() => isSignUp = !isSignUp),
              child: Text(isSignUp ? 'Have account? Sign In' : 'Need account? Sign Up', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              onPressed: () async {
                try {
                  if (Firebase.apps.isNotEmpty) {
                    if (isSignUp) {
                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    } else {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onAuthChanged();
                } catch (e) {
                  setDialogState(() => authError = e.toString());
                }
              },
              child: Text(isSignUp ? 'Register' : 'Sign In', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      widget.onAuthChanged();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  void _deleteListing(String id) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('listings').doc(id).delete();
      }
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted successfully.')));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  void _toggleSold(GridListing item) async {
    try {
      item.isSold = !item.isSold;
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('listings').doc(item.id).update({'isSold': item.isSold});
      }
      setState(() {});
    } catch (e) {
      debugPrint('Update sold error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final userListings = widget.listings.where((l) => l.authorId == user?.uid || l.authorId == 'apex_fab').toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF10141C),
              child: Icon(Icons.factory, size: 40, color: Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.email ?? (user == null || user.isAnonymous ? 'Guest Industrial Partner' : 'Verified Spot Enterprise'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Center(child: Text('Joined October 2026 • ★ 4.9 Verified Spot Industrial Partner', style: TextStyle(fontSize: 12, color: Color(0xFF8E9BAE)))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user == null || user.isAnonymous)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                  onPressed: _openAuthDialog,
                  child: const Text('Sign In / Register Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00E5FF))),
                  onPressed: _signOut,
                  child: const Text('Sign Out', style: TextStyle(color: Color(0xFF00E5FF))),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('🏭 SPOT INDUSTRIAL SHOWCASE & PAST WORK', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          if (userListings.isEmpty)
            const Center(child: Text('No jobs near you yet — post the first one.', style: TextStyle(color: Color(0xFF8E9BAE), fontSize: 12)))
          else
            ...userListings.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF10141C), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E2638))),
              child: Row(
                children: [
                  Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (item.isVerified) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.verified, color: Color(0xFF00E5FF), size: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${item.price} • ${item.isSold ? '🔴 SOLD / COMPLETED' : '🟢 ACTIVE'}', style: TextStyle(color: item.isSold ? Colors.redAccent : const Color(0xFF00E5FF), fontSize: 11)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF8E9BAE)),
                    color: const Color(0xFF10141C),
                    onSelected: (val) {
                      if (val == 'sold') {
                        _toggleSold(item);
                      } else if (val == 'delete') {
                        _deleteListing(item.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'sold', child: Text(item.isSold ? 'Mark Active' : 'Mark Sold / Completed', style: const TextStyle(fontSize: 12, color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Listing', style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                    ],
                  ),
                ],
              ),
            )),
          const SizedBox(height: 24),
          ListTile(
            tileColor: const Color(0xFF10141C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF1E2638))),
            leading: const Icon(Icons.verified_user, color: Color(0xFF00E5FF)),
            title: const Text('Spot Industrial Tier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: const Text('Verified Industrial Showcase • 18 Completed Contracts', style: TextStyle(fontSize: 11, color: Color(0xFF8E9BAE))),
          ),
        ],
      ),
    );
  }
}
