import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'agent_detail_screen.dart';

class AgentManagementScreen extends StatefulWidget {
  const AgentManagementScreen({super.key});

  @override
  State<AgentManagementScreen> createState() => _AgentManagementScreenState();
}

class _AgentManagementScreenState extends State<AgentManagementScreen> {
  // Support DB Client
  final _supportClient = SupabaseClient(
    'https://lbdmdeutmuppgsbzrxcy.supabase.co',
    'sb_publishable_IWjNg9Xc6cFGd9JgEOA3Hg_G-CA32h8',
  );

  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      // Get unique agents from support_tickets (more reliable - has actual data)
      final tickets = await _supportClient
          .from('support_tickets')
          .select('agent_id, agent_email')
          .not('agent_id', 'is', null);

      // Extract unique agents
      final Map<String, Map<String, dynamic>> uniqueAgents = {};
      for (var ticket in tickets) {
        final agentId = ticket['agent_id'];
        if (agentId != null && !uniqueAgents.containsKey(agentId)) {
          var email = ticket['agent_email'];
          
          // If no email in ticket, try to get from support_agents table
          if (email == null) {
            try {
              final agentRecord = await _supportClient
                  .from('support_agents')
                  .select('email')
                  .eq('id', agentId)
                  .maybeSingle();
              email = agentRecord?['email'];
            } catch (e) {
              // Ignore errors
            }
          }
          
          final displayEmail = email ?? 'ID: ${agentId.toString().substring(0, 8)}...';
          uniqueAgents[agentId] = {
            'id': agentId,
            'email': displayEmail,
            'name': email?.split('@').first ?? 'Agent ${agentId.toString().substring(0, 6)}',
          };
        }
      }

      // Also try to get ban status from support_agents
      for (var agentId in uniqueAgents.keys) {
        try {
          final agentData = await _supportClient
              .from('support_agents')
              .select('is_banned')
              .eq('id', agentId)
              .maybeSingle();
          if (agentData != null) {
            uniqueAgents[agentId]!['is_banned'] = agentData['is_banned'] ?? false;
          } else {
            uniqueAgents[agentId]!['is_banned'] = false;
          }
        } catch (e) {
          uniqueAgents[agentId]!['is_banned'] = false;
        }
      }

      if (mounted) {
        setState(() {
          _agents = uniqueAgents.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading agents: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text('Agent Management', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAgents();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _agents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No agents have handled tickets yet', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Agents will appear here after they claim tickets', 
                           style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAgents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _agents.length,
                    itemBuilder: (context, index) {
                      final agent = _agents[index];
                      return _buildAgentCard(agent);
                    },
                  ),
                ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final email = agent['email'] ?? 'No Email';
    final name = agent['name'] ?? email.split('@').first;
    final isBanned = agent['is_banned'] == true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isBanned ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgentDetailScreen(agent: agent, supportClient: _supportClient),
            ),
          );
          _loadAgents(); // Refresh after returning
        },
        leading: CircleAvatar(
          backgroundColor: isBanned ? Colors.red.shade50 : const Color(0xFF2DA931).withOpacity(0.1),
          child: Icon(
            isBanned ? Icons.block : Icons.support_agent,
            color: isBanned ? Colors.red : const Color(0xFF2DA931),
          ),
        ),
        title: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        subtitle: Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: isBanned
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('BANNED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
