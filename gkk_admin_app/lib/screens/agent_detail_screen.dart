import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> agent;
  final SupabaseClient supportClient;

  const AgentDetailScreen({
    super.key,
    required this.agent,
    required this.supportClient,
  });

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  int _ticketsSolved = 0;
  int _ticketsActive = 0;
  int _ticketsTotal = 0;
  bool _isLoading = true;
  late bool _isBanned;

  @override
  void initState() {
    super.initState();
    _isBanned = widget.agent['is_banned'] == true;
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final agentId = widget.agent['id'];

      final allTickets = await widget.supportClient
          .from('support_tickets')
          .select('id, status')
          .eq('agent_id', agentId);

      int solved = 0;
      int active = 0;

      for (var ticket in allTickets) {
        if (ticket['status'] == 'closed') solved++;
        if (ticket['status'] == 'active') active++;
      }

      if (mounted) {
        setState(() {
          _ticketsSolved = solved;
          _ticketsActive = active;
          _ticketsTotal = allTickets.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBanned ? 'Unban Agent?' : 'Ban Agent?'),
        content: Text(
          _isBanned
              ? 'This agent will be able to login again.'
              : 'This agent will be immediately disconnected and cannot login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBanned ? const Color(0xFF2DA931) : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_isBanned ? 'Unban' : 'Ban'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Upsert the agent record (creates if not exists)
        await widget.supportClient.from('support_agents').upsert({
          'id': widget.agent['id'],
          'email': widget.agent['email'],
          'name': widget.agent['name'],
          'is_banned': !_isBanned,
          'banned_at': _isBanned ? null : DateTime.now().toIso8601String(),
        });

        setState(() => _isBanned = !_isBanned);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isBanned ? 'Agent has been banned' : 'Agent has been unbanned',
              ),
              backgroundColor: _isBanned ? Colors.red : const Color(0xFF2DA931),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.agent['email'] ?? 'No Email';
    final name = widget.agent['name'] ?? email.split('@').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'Agent Details',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Agent Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _isBanned
                              ? Colors.red.shade50
                              : const Color(0xFF2DA931).withOpacity(0.1),
                          child: Icon(
                            _isBanned ? Icons.block : Icons.support_agent,
                            size: 40,
                            color: _isBanned
                                ? Colors.red
                                : const Color(0xFF2DA931),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(email, style: TextStyle(color: Colors.grey[600])),
                        if (_isBanned) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '⛔ BANNED',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Analytics Section
                  Text(
                    'Performance Analytics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Solved',
                          _ticketsSolved,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Active',
                          _ticketsActive,
                          Colors.orange,
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Total Handled',
                    _ticketsTotal,
                    const Color(0xFF2DA931),
                    Icons.support_agent,
                  ),

                  const SizedBox(height: 32),

                  // Ban/Unban Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleBan,
                      icon: Icon(_isBanned ? Icons.check_circle : Icons.block),
                      label: Text(
                        _isBanned ? 'UNBAN AGENT' : 'REVOKE / BAN AGENT',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBanned
                            ? const Color(0xFF2DA931)
                            : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
