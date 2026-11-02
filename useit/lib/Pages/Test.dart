import 'dart:convert';
import 'dart:io';

const token = 'EAAAl4P0-Jdsxq0jW4bpgTHDsTUJRUZ5vzBTPbjcM_KxBnlH4i3W6xEHuJtTozH0';
const cardId = 'gan:7783321330214634';

Future<void> main() async {
  final url = 'https://connect.squareupsandbox.com/v2/gift-cards';
  final req = await HttpClient().getUrl(Uri.parse(url));
  req.headers.set('Authorization', 'Bearer $token');
  req.headers.set('Square-Version', '2026-09-16');
  final res = await req.close();
  print(await res.transform(utf8.decoder).join());
}