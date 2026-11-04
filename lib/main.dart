import 'package:flutter/material.dart';

void main() => runApp(const AnLanhApp());

const ink = Color(0xff203b31);
const green = Color(0xff287052);
const canvas = Color(0xfffafaf6);
const line = Color(0xffd8e0d9);

enum Result { good, warn, bad, unknown }

class Food {
  const Food({
    required this.id,
    required this.brand,
    required this.name,
    required this.weight,
    required this.tone,
    required this.result,
    required this.sugar,
    required this.salt,
    required this.nova,
    required this.reason,
    required this.ingredients,
  });
  final String id, brand, name, weight, tone, sugar, salt, nova, reason, ingredients;
  final Result result;
}

const foods = [
  Food(
    id: 'cocoa',
    brand: 'Mộc Hạt',
    name: 'Bánh yến mạch cacao',
    weight: '180 g',
    tone: 'brown',
    result: Result.bad,
    sugar: '18 g',
    salt: '0,42 g',
    nova: '4',
    reason: 'Có sữa 8% và thuộc NOVA 4, không phù hợp với hồ sơ hiện tại.',
    ingredients: 'Yến mạch 45%, bột mì, đường, dầu cọ, bột sữa 8%, cacao 4%, muối.',
  ),
  Food(
    id: 'original',
    brand: 'An Mộc',
    name: 'Bánh yến mạch nguyên bản',
    weight: '160 g',
    tone: 'green',
    result: Result.good,
    sugar: '4,2 g',
    salt: '0,12 g',
    nova: '3',
    reason: 'Đủ dữ liệu, không ghi nhận vi phạm tiêu chí trong hồ sơ.',
    ingredients: 'Yến mạch 65%, bột mì nguyên cám 20%, đường dừa 4%, muối 0,12%.',
  ),
  Food(
    id: 'rice',
    brand: 'Lúa Nhỏ',
    name: 'Bánh gạo mè',
    weight: '120 g',
    tone: 'gold',
    result: Result.warn,
    sugar: '12 g',
    salt: '0,35 g',
    nova: '3',
    reason: 'Đường và muối vượt nhẹ mức cá nhân đã đặt.',
    ingredients: 'Gạo 65%, mè 10%, đường 12%, dầu cải, muối 0,35%.',
  ),
  Food(
    id: 'nut',
    brand: 'Hạt Sớm',
    name: 'Thanh hạt vị dừa',
    weight: '35 g',
    tone: 'slate',
    result: Result.unknown,
    sugar: '6 g',
    salt: 'Chưa có dữ liệu',
    nova: 'Chưa có dữ liệu',
    reason: 'Thiếu thành phần và thông tin dị ứng nên chưa thể kết luận.',
    ingredients: 'Chưa có dữ liệu',
  ),
];

String resultLabel(Result result) => switch (result) {
      Result.good => 'Phù hợp',
      Result.warn => 'Cần cân nhắc',
      Result.bad => 'Không phù hợp',
      Result.unknown => 'Chưa đủ dữ liệu',
    };

Color resultColor(Result result) => switch (result) {
      Result.good => const Color(0xff287052),
      Result.warn => const Color(0xff986c12),
      Result.bad => const Color(0xffb54032),
      Result.unknown => const Color(0xff526b82),
    };

Color resultBackground(Result result) => switch (result) {
      Result.good => const Color(0xffe6f2e8),
      Result.warn => const Color(0xfffff2d6),
      Result.bad => const Color(0xfffde9e5),
      Result.unknown => const Color(0xffe8f0f7),
    };

IconData resultIcon(Result result) => switch (result) {
      Result.good => Icons.check_circle_outline,
      Result.warn => Icons.warning_amber_outlined,
      Result.bad => Icons.cancel_outlined,
      Result.unknown => Icons.help_outline,
    };

class AnLanhApp extends StatelessWidget {
  const AnLanhApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ăn Lành',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          fontFamily: 'sans',
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: ink, height: 1.45),
            titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  Food selected = foods.first;

  void open(Food food) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPage(food: food)),
      );

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onScan: () => setState(() => tab = 1), onOpen: open),
      ScanPage(onProduct: () => open(foods.first)),
      HistoryPage(onOpen: open),
      ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffe4f0e5),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Quét'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.back = false});
  final String title;
  final String? subtitle;
  final bool back;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          children: [
            if (back) ...[
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xff6d7f77))),
                ],
              ),
            ),
          ],
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.result, {super.key});
  final Result result;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: resultBackground(result), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resultIcon(result), size: 15, color: resultColor(result)),
            const SizedBox(width: 5),
            Text(resultLabel(result), style: TextStyle(color: resultColor(result), fontSize: 12)),
          ],
        ),
      );
}

class Pack extends StatelessWidget {
  const Pack({super.key, required this.food, this.small = false});
  final Food food;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final color = {'brown': const Color(0xff79543f), 'green': const Color(0xff5e7d52), 'gold': const Color(0xffb88b43), 'slate': const Color(0xff82919a)}[food.tone]!;
    return Container(
      width: small ? 64 : 132,
      height: small ? 78 : 174,
      padding: EdgeInsets.all(small ? 5 : 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(food.brand, style: TextStyle(color: Colors.white, fontSize: small ? 7 : 12, fontWeight: FontWeight.w700)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: small ? 7 : 12, horizontal: 3),
            decoration: BoxDecoration(color: const Color(0xfffff5e3), borderRadius: BorderRadius.circular(5)),
            child: Column(children: [
              Text('⌁', style: TextStyle(color: color, fontSize: small ? 16 : 29)),
              Text(food.name.replaceFirst('Bánh ', ''), textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: small ? 6 : 11, fontWeight: FontWeight.w700)),
            ]),
          ),
          Text(food.weight, style: TextStyle(color: Colors.white, fontSize: small ? 6 : 10)),
        ],
      ),
    );
  }
}

class FoodTile extends StatelessWidget {
  const FoodTile({super.key, required this.food, required this.onTap});
  final Food food;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: line)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Pack(food: food, small: true),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(food.brand, style: const TextStyle(fontSize: 11, color: Color(0xff6d7f77))),
                Text(food.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                StatusBadge(food.result),
                const SizedBox(height: 3),
                Text(food.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xff6d7f77))),
              ])),
              const Icon(Icons.chevron_right, color: green),
            ]),
          ),
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onScan, required this.onOpen});
  final VoidCallback onScan;
  final void Function(Food) onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('ĂN LÀNH', style: TextStyle(color: green, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('Hiểu nhãn.\nChọn theo mình.', style: TextStyle(fontSize: 31, height: 1.12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        const Text('Chào bạn, cùng đọc nhãn nhé!', style: TextStyle(color: Color(0xff6d7f77))),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: const Color(0xffe8f2e7), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Một lần quét.\nHiểu rõ hơn.', style: TextStyle(fontSize: 27, height: 1.1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Xem thực phẩm có phù hợp với hồ sơ ăn uống của bạn.'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onScan, icon: const Icon(Icons.qr_code_scanner), label: const Text('Quét mã vạch'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
          ]),
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: line)),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.person_outline, color: green), const SizedBox(width: 8), const Text('Hồ sơ đang áp dụng', style: TextStyle(fontWeight: FontWeight.w600)), const Spacer(), TextButton(onPressed: () {}, child: const Text('Chỉnh sửa'))]),
            Wrap(spacing: 7, children: ['Dị ứng sữa', 'Dị ứng đậu phộng'].map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 11)))).toList()),
            const Text('Hạn chế đường, muối · Tránh NOVA 4', style: TextStyle(color: Color(0xff6d7f77), fontSize: 13)),
          ])),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.compare_arrows), label: const Text('Đặt hai nhãn cạnh nhau'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), alignment: Alignment.centerLeft)),
        const SizedBox(height: 18),
        const Text('Đánh giá gần đây', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        FoodTile(food: foods.first, onTap: () => onOpen(foods.first)),
        const Text('Đánh giá theo hồ sơ cá nhân, chỉ mang tính tham khảo.', style: TextStyle(fontSize: 12, color: Color(0xff6d7f77))),
      ]);
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.onProduct});
  final VoidCallback onProduct;
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool failed = false;
  @override
  Widget build(BuildContext context) => Column(children: [
        const PageHeader(title: 'Quét mã vạch', subtitle: 'Giữ thông tin rõ và đủ sáng'),
        Expanded(
          child: Column(children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xff787866),
                child: Stack(alignment: Alignment.center, children: [
                  Positioned(top: 68, child: Chip(label: Text(failed ? 'Không quét được mã' : 'Đưa mã vạch vào khung'))),
                  Container(width: 320, height: 190, decoration: BoxDecoration(border: Border.all(color: failed ? Colors.red : Colors.white, width: 2), borderRadius: BorderRadius.circular(20))),
                  Positioned(bottom: 55, child: FilledButton.icon(onPressed: () => setState(() => failed = !failed), icon: const Icon(Icons.document_scanner), label: Text(failed ? 'Quét bảng thành phần' : 'Bật đèn'))),
                ]),
              ),
            ),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(failed ? 'Giữ bảng rõ và đủ sáng' : 'Giữ mã rõ và đủ sáng', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Giữ điện thoại ổn định. Ăn Lành sẽ dùng thông tin để tra cứu sản phẩm.'),
              const SizedBox(height: 12),
              const Text('Không lưu ảnh từ camera · Nguồn dự kiến: Open Food Facts', style: TextStyle(color: Color(0xff6d7f77), fontSize: 12)),
              const SizedBox(height: 14),
              FilledButton(onPressed: widget.onProduct, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)), child: const Text('Xem sản phẩm mẫu')),
            ])),
          ]),
        ),
      ]);
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.food});
  final Food food;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
          const PageHeader(title: 'Chi tiết sản phẩm', subtitle: 'Đánh giá theo hồ sơ đang lưu', back: true),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: resultBackground(food.result), borderRadius: BorderRadius.circular(20)), child: Row(children: [Pack(food: food), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${food.brand} · ${food.weight}', style: const TextStyle(color: Color(0xff6d7f77), fontSize: 12)), const SizedBox(height: 7), Text(food.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 12), const Text('Mã vạch 8930000000128', style: TextStyle(color: Color(0xff6d7f77), fontSize: 11))]))])),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: resultBackground(food.result), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [StatusBadge(food.result), const SizedBox(height: 16), Text(food.result == Result.bad ? 'Có sữa, không hợp hồ sơ của bạn' : food.result == Result.unknown ? 'Chưa thể kết luận phù hợp' : 'Phù hợp với hồ sơ của bạn', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(food.reason), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExplanationPage(food: food))), icon: const Icon(Icons.lightbulb_outline), label: const Text('Xem giải thích theo tiêu chí'))])),
          InfoCard(title: 'Thành phần', child: Text(food.ingredients)),
          InfoCard(title: 'Dinh dưỡng', child: Column(children: [DataRowWidget(label: 'Đường', value: food.sugar), DataRowWidget(label: 'Muối', value: food.salt), const SizedBox(height: 8), const Text('Mức cá nhân: đường 10 g và muối 0,30 g trên 100 g.', style: TextStyle(color: Color(0xff6d7f77), fontSize: 12))])),
          InfoCard(title: 'Thông tin bổ sung', child: Column(children: [DataRowWidget(label: 'NOVA', value: food.nova), DataRowWidget(label: 'Nutri-Score', value: food.result == Result.unknown ? 'Chưa có dữ liệu' : 'C'), DataRowWidget(label: 'Eco-Score', value: food.result == Result.unknown ? 'Chưa có dữ liệu' : 'B')])),
          const Text('Sản phẩm tham khảo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...foods.where((item) => item.id != food.id).take(3).map((item) => FoodTile(food: item, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DetailPage(food: item))))),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.compare_arrows), label: const Text('Chọn 2 sản phẩm để so sánh'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52))),
          const SizedBox(height: 18),
          const Text('Chỉ mang tính tham khảo theo hồ sơ cá nhân, không phải chẩn đoán y khoa.', style: TextStyle(color: Color(0xff6d7f77), fontSize: 12)),
        ])),
      );
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, margin: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: line)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 10), child])));
}

class DataRowWidget extends StatelessWidget {
  const DataRowWidget({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Color(0xff6d7f77)))), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]));
}

class ExplanationPage extends StatelessWidget {
  const ExplanationPage({super.key, required this.food});
  final Food food;
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
        const PageHeader(title: 'Vì sao có kết quả này?', subtitle: 'Bánh yến mạch cacao · Mộc Hạt', back: true),
        StatusBadge(food.result),
        const SizedBox(height: 14),
        const Text('Kết luận dựa trên 5 tiêu chí bạn đã chọn. Dị ứng sữa và NOVA 4 là các lý do quyết định.', style: TextStyle(fontSize: 15)),
        ...[
          ['Dị ứng sữa', 'Thành phần ghi “bột sữa 8%”. Đây là thành phần từ sữa, trùng tiêu chí dị ứng của bạn.', Result.bad],
          ['Dị ứng đậu phộng', 'Thông tin minh họa đầy đủ; không ghi nhận đậu phộng.', Result.good],
          ['Hạn chế đường', 'Đường 18 g/100 g, vượt mức cá nhân tối đa 10 g/100 g.', Result.warn],
          ['Hạn chế muối', 'Muối 0,42 g/100 g, vượt mức cá nhân tối đa 0,30 g/100 g.', Result.warn],
          ['Tránh NOVA 4', 'Sản phẩm thuộc nhóm thực phẩm siêu chế biến mà bạn chọn tránh.', Result.bad],
        ].map((item) => Card(elevation: 0, margin: const EdgeInsets.only(top: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: line)), child: ListTile(leading: Icon(resultIcon(item.$3), color: resultColor(item.$3)), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(item.$2))))),
        Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xffe9f1f8), borderRadius: BorderRadius.circular(14)), child: const Text('Dữ liệu cần thiết đã có\nKhông đủ thành phần, dị ứng, đường, muối hoặc NOVA thì không thể đánh giá. Không tự động kết luận phù hợp.')),
      ])));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.onOpen});
  final void Function(Food) onOpen;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const PageHeader(title: 'Lịch sử đánh giá', subtitle: '4 sản phẩm · Lưu trên thiết bị'),
        Wrap(spacing: 7, children: ['Tất cả', 'Không phù hợp', 'Chưa đủ dữ liệu'].map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 11)))).toList()),
        const SizedBox(height: 10),
        const Text('Chọn một sản phẩm để xem lại kết luận và lý do theo hồ sơ.', style: TextStyle(color: Color(0xff6d7f77), fontSize: 13)),
        const SizedBox(height: 18),
        const Text('Hôm nay', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...foods.take(2).map((food) => FoodTile(food: food, onTap: () => onOpen(food))),
        const Text('Hôm qua', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...foods.skip(2).map((food) => FoodTile(food: food, onTap: () => onOpen(food))),
      ];
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const PageHeader(title: 'Hồ sơ ăn uống', subtitle: 'Tiêu chí của bạn, lựa chọn của bạn'),
        const Text('Chọn những điều bạn muốn kiểm tra khi đọc nhãn thực phẩm.', style: TextStyle(fontSize: 15)),
        Preference(title: 'Dị ứng thực phẩm', items: const ['Sữa', 'Đậu phộng', 'Gluten'], checked: const ['Sữa', 'Đậu phộng']),
        Preference(title: 'Mức hạn chế cá nhân', items: const ['Hạn chế đường ≤ 10 g / 100 g', 'Hạn chế muối ≤ 0,30 g / 100 g', 'Tránh thực phẩm NOVA 4'], checked: const ['Hạn chế đường ≤ 10 g / 100 g', 'Hạn chế muối ≤ 0,30 g / 100 g', 'Tránh thực phẩm NOVA 4']),
        Preference(title: 'Chế độ ăn', items: const ['Ăn chay có trứng và sữa', 'Ăn chay có sữa', 'Thuần chay', 'Chế độ Keto'], checked: const ['Ăn chay có trứng và sữa'], radio: true),
        Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(top: 14), decoration: BoxDecoration(color: const Color(0xffe9f3e7), borderRadius: BorderRadius.circular(14)), child: const Text('Hồ sơ chỉ lưu trên thiết bị này\nKhông cần tài khoản. Bạn có thể chỉnh sửa hoặc xóa hồ sơ bất cứ lúc nào.')),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.check), label: const Text('Lưu hồ sơ'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () {}, child: const Text('Xóa hồ sơ'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xffb54032), minimumSize: const Size.fromHeight(52))),
      ];
}

class Preference extends StatelessWidget {
  const Preference({super.key, required this.title, required this.items, required this.checked, this.radio = false});
  final String title;
  final List<String> items, checked;
  final bool radio;
  @override
  Widget build(BuildContext context) => Card(elevation: 0, margin: const EdgeInsets.only(top: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: line)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), ...items.map((item) => Row(children: [radio ? Radio<bool>(value: checked.contains(item), groupValue: true, onChanged: (_) {}) : Checkbox(value: checked.contains(item), onChanged: (_) {}), Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w500)))]))])));
}
