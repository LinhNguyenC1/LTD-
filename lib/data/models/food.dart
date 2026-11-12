enum Result { good, warn, bad, unknown }

class Food {
  final String id;
  final String brand;
  final String name;
  final String weight;
  final String barcode;
  final String tone; // 'brown', 'green', 'gold', 'slate'
  final Result result;
  final String sugar;
  final String salt;
  final String nova;
  final String nutriScore;
  final String ecoScore;
  final String reason;
  final String ingredients;
  final String allergenWarning;
  final String scanDate;
  final String summaryTags;

  const Food({
    required this.id,
    required this.brand,
    required this.name,
    required this.weight,
    required this.barcode,
    required this.tone,
    required this.result,
    required this.sugar,
    required this.salt,
    required this.nova,
    required this.nutriScore,
    required this.ecoScore,
    required this.reason,
    required this.ingredients,
    required this.allergenWarning,
    required this.scanDate,
    required this.summaryTags,
  });
}

const Food foodOriginal = Food(
  id: 'original',
  brand: 'An Mộc',
  name: 'Bánh yến mạch nguyên bản',
  weight: '160 g',
  barcode: '8930000000129',
  tone: 'green',
  result: Result.good,
  sugar: '4,2 g',
  salt: '0,12 g',
  nova: '3',
  nutriScore: 'B',
  ecoScore: 'A',
  reason: 'Đủ dữ liệu, không ghi nhận vi phạm tiêu chí trong hồ sơ.',
  ingredients:
      'Yến mạch 65%, bột mì nguyên cám 20%, dầu cải 8%, đường dừa 4%, nước 2,88%, muối 0,12%.',
  allergenWarning:
      'Dữ liệu dị ứng minh họa đầy đủ; xác nhận không chứa sữa và đậu phộng; có gluten (không chọn trong hồ sơ).',
  scanDate: 'Hôm nay, 09:20',
  summaryTags: 'Đủ dữ liệu, không vi phạm hồ sơ',
);

const Food foodCocoa = Food(
  id: 'cocoa',
  brand: 'Mộc Hạt',
  name: 'Bánh yến mạch cacao',
  weight: '180 g',
  barcode: '8930000000128',
  tone: 'brown',
  result: Result.bad,
  sugar: '18 g',
  salt: '0,42 g',
  nova: '4',
  nutriScore: 'C',
  ecoScore: 'B',
  reason: 'Có sữa 8% trùng tiêu chí dị ứng sữa. Sản phẩm cũng thuộc NOVA 4 mà bạn chọn tránh.',
  ingredients:
      'Yến mạch 45%, bột mì, đường, dầu cọ, bột sữa 8%, cacao 4%, chất nhũ hóa (lecithin đậu nành), muối.',
  allergenWarning:
      'Có sữa, gluten, đậu nành. Thông tin dị ứng minh họa đầy đủ; không ghi nhận đậu phộng.',
  scanDate: 'Hôm nay, 09:32',
  summaryTags: 'Có sữa • NOVA 4',
);

const Food foodRice = Food(
  id: 'rice',
  brand: 'Lúa Nhỏ',
  name: 'Bánh gạo mè',
  weight: '120 g',
  barcode: '8930000000789',
  tone: 'gold',
  result: Result.warn,
  sugar: '12 g',
  salt: '0,35 g',
  nova: '3',
  nutriScore: 'B',
  ecoScore: 'B',
  reason: 'Đường và muối vượt nhẹ mức cá nhân đã đặt.',
  ingredients: 'Gạo 65%, mè 10%, đường 12%, dầu cải, muối 0,35%.',
  allergenWarning: 'Không ghi nhận sữa hoặc đậu phộng.',
  scanDate: 'Hôm qua, 10:12',
  summaryTags: 'Đường 12 g; muối 0,35 g /100 g',
);

const Food foodNut = Food(
  id: 'nut',
  brand: 'Hạt Sớm',
  name: 'Thanh hạt vị dừa',
  weight: '35 g',
  barcode: '8930000000456',
  tone: 'slate',
  result: Result.unknown,
  sugar: '6 g',
  salt: 'Chưa có dữ liệu',
  nova: 'Chưa có dữ liệu',
  nutriScore: 'Chưa có dữ liệu',
  ecoScore: 'Chưa có dữ liệu',
  reason: 'Thiếu thành phần và thông tin dị ứng nên chưa kiểm tra được sữa hoặc đậu phộng trong hồ sơ của bạn.',
  ingredients: 'Chưa có dữ liệu',
  allergenWarning: 'Chưa có dữ liệu',
  scanDate: 'Hôm qua, 16:45',
  summaryTags: 'Thiếu thành phần / dị ứng',
);

const List<Food> mockFoods = [
  foodCocoa,
  foodOriginal,
  foodNut,
  foodRice,
];
