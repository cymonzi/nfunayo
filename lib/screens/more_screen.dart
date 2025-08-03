import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'collaborators_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> latestPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLatestPosts();
  }

  Future<void> fetchLatestPosts() async {
    final url = Uri.parse(
      'https://thetechtower.com/wp-json/wp/v2/posts?per_page=3',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> posts = json.decode(response.body);
        setState(() {
          latestPosts =
              posts
                  .map(
                    (post) => {
                      'title': post['title']['rendered'],
                      'link': post['link'],
                    },
                  )
                  .toList();
          isLoading = false;
        });
      } else {
        showSnackbar('Failed to fetch posts.');
      }
    } catch (e) {
      showSnackbar('Error fetching posts: $e');
    }
  }

  void showSnackbar(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showSnackbar('Could not open link: $url');
    }
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'For You!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Explore the latest updates and discoveries.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLitywiseCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              'assets/images/panda.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The Litywise Game',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Litywise is an educational game teaching financial literacy in a fun way.',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Add action to open app or store
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Download Litywise',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          "📺 Financial Literacy YouTube",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildYouTubeCard(
          title: "Patrick Bitature - Uganda",
          subtitle: "@patrickbitaturesimba",
          link: "https://youtube.com/@patrickbitaturesimba?si=ZpdDD9O6z2WkOmvb",
        ),
        _buildYouTubeCard(
          title: "Money & Business Tips",
          subtitle: "Powerful business insights",
          link: "https://youtu.be/6J2S70Mm-iU?si=24NbiErgjIOw2b4K",
        ),
        _buildYouTubeCard(
          title: "Financially Incorrect - East Africa",
          subtitle: "@financially_incorrect",
          link:
              "https://youtube.com/@financially_incorrect?si=i_1epi2LwAZ10vLX",
        ),
        _buildYouTubeCard(
          title: "Nischa - India",
          subtitle: "@nischa",
          link: "https://youtube.com/@nischa?si=yefkQl93Cf_6d5Jd",
        ),
        _buildYouTubeCard(
          title: "Diary of a CEO - UK",
          subtitle: "@thediaryofaceo",
          link: "https://youtube.com/@thediaryofaceo?si=h6pVS6ZTq-SG1Ebg",
        ),
      ],
    );
  }

  Widget _buildYouTubeCard({
    required String title,
    required String subtitle,
    required String link,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        tileColor: const Color.fromARGB(255, 248, 250, 251),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new, color: Colors.blueAccent),
        onTap: () => _openLink(link),
      ),
    );
  }

  Widget _buildTechTowerPosts() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest from TechTower',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (latestPosts.isEmpty)
              const Text('No posts available.')
            else
              Column(
                children:
                    latestPosts
                        .map(
                          (post) => ListTile(
                            leading: const Icon(
                              Icons.article_outlined,
                              color: Colors.blue,
                            ),
                            title: Text(
                              post['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            onTap: () => _openLink(post['link']),
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.shade100,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Collaborators Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.group, color: Colors.white),
                ),
                title: const Text(
                  'Collaborators',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Share expenses with friends and family'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CollaboratorsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildHeroSection(),
            const SizedBox(height: 20),
            _buildLitywiseCard(),
            const SizedBox(height: 20),
            _buildYouTubeSection(),
            const SizedBox(height: 20),
            _buildTechTowerPosts(),
          ],
        ),
      ),
    );
  }
}
