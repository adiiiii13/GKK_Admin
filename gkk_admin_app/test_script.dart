import 'package:supabase_flutter/supabase_flutter.dart';
void main() {
  final client = SupabaseClient('url', 'anonKey');
  Future.wait([
    client.from('kitchen_applications').select('*').eq('status', 'PENDING').count(CountOption.exact)
  ]).then((results) {
    print(results[0].runtimeType);
  });
}
