import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SupportMonitorScreen extends StatefulWidget {
  const SupportMonitorScreen({super.key});

  @override
  State<SupportMonitorScreen> createState() => _SupportMonitorScreenState();
}

class _SupportMonitorScreenState extends State<SupportMonitorScreen> {
  // Dedicated Support DB Client
  final _supportClient = SupabaseClient(
    'https://lbdmdeutmuppgsbzrxcy.supabase.co',
    'sb_publishable_IWjNg9Xc6cFGd9JgEOA3Hg_G-CA32h8',
  );

  // GKK Basic DB Client (User App's Database for fetching user names)
  final _userDbClient = SupabaseClient(
    'https://mwnpwuxrbaousgwgoyco.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im13bnB3dXhyYmFvdXNnd2dveWNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5ODU2MzYsImV4cCI6MjA4MzU2MTYzNn0.dTM9rguaiuHbrr59iPUsM5znDzXhOdRXbPQ11yOfZpM',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text('Customer Tickets', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supportClient
            .from('support_tickets')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false), // Newest first for Admin
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tickets = snapshot.data!;
          if (tickets.isEmpty) return const Center(child: Text('No tickets found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _buildTicketCard(ticket);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'];
    final time = DateTime.parse(ticket['created_at']).toLocal();
    final agentId = ticket['agent_id'];
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => SupportChatViewer(ticket: ticket, client: _supportClient))
        ),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
          child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
        ),
        title: Text(
          'Ticket #${ticket['id'].toString().substring(0, 8)}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created: ${DateFormat('MMM d, h:mm a').format(time)}'),
            if (agentId != null) 
              Text(
                'Agent: ...${agentId.toString().substring(0, 6)}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              )
            else
              const Text('Unassigned', style: TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toString().toUpperCase(),
            style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'open') return Colors.orange;
    if (status == 'active') return Colors.green;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'open') return Icons.priority_high;
    if (status == 'active') return Icons.headset_mic;
    return Icons.check_circle;
  }
}

class SupportChatViewer extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final SupabaseClient client;

  const SupportChatViewer({super.key, required this.ticket, required this.client});

  @override
  State<SupportChatViewer> createState() => _SupportChatViewerState();
}

class _SupportChatViewerState extends State<SupportChatViewer> {
  String _userName = 'Loading...';
  String _agentEmail = 'Loading...';

  // GKK Basic DB Client (User App's Database)
  final _userDbClient = SupabaseClient(
    'https://mwnpwuxrbaousgwgoyco.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im13bnB3dXhyYmFvdXNnd2dveWNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5ODU2MzYsImV4cCI6MjA4MzU2MTYzNn0.dTM9rguaiuHbrr59iPUsM5znDzXhOdRXbPQ11yOfZpM',
  );

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      // 1. Fetch User Name from User App DB (GKK Basic)
      final userId = widget.ticket['user_id'];
      String uName = 'Unknown User';
      
      if (userId != null) {
        final userRes = await _userDbClient
            .from('users')
            .select('name, email')
            .eq('id', userId)
            .maybeSingle();
        
        if (userRes != null) {
           uName = userRes['name'] ?? userRes['email'] ?? 'Unknown User';
        }
      }

      // 2. Fetch Agent Email - First check if it's stored directly in ticket
      final agentId = widget.ticket['agent_id'];
      final ticketAgentEmail = widget.ticket['agent_email'];
      String aEmail = 'Unassigned';

      if (ticketAgentEmail != null && ticketAgentEmail.toString().isNotEmpty) {
         // Use email stored directly in ticket
         aEmail = ticketAgentEmail;
      } else if (agentId != null) {
         // Fallback: Query support_agents table
         final agentRes = await widget.client
             .from('support_agents')
             .select('email, name')
             .eq('id', agentId)
             .maybeSingle();
         
         if (agentRes != null) {
            aEmail = agentRes['email'] ?? agentRes['name'] ?? 'Agent';
         } else {
            aEmail = 'Agent: ${agentId.toString().substring(0,6)}...'; 
         }
      }

      if (mounted) {
        setState(() {
          _userName = uName;
          _agentEmail = aEmail;
        });
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
      if (mounted) {
        setState(() {
           _userName = 'Error';
           _agentEmail = 'Error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('User', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.blue.shade200),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Agent', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(_agentEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chat Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.client
                  .from('chat_messages')
                  .stream(primaryKey: ['id'])
                  .eq('ticket_id', widget.ticket['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;

                if (messages.isEmpty) return const Center(child: Text('No messages yet.'));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isAgent = msg['is_agent'] as bool;
                    final time = DateTime.parse(msg['created_at']).toLocal();

                    return Align(
                      alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isAgent ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isAgent ? Colors.green.shade100 : Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                               isAgent ? 'Agent' : 'User',
                               style: TextStyle(
                                 fontSize: 10, 
                                 fontWeight: FontWeight.bold,
                                 color: isAgent ? Colors.green : Colors.blue
                               ),
                            ),
                            const SizedBox(height: 4),
                            Text(msg['message'], style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(time),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
