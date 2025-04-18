import 'package:flutter/material.dart';
import 'package:pokemon_market/pages/product_detail_page.dart';
import 'package:pokemon_market/widgets/common_img.dart';
import 'package:pokemon_market/widgets/common_text.dart';
import 'package:pokemon_market/theme/custom_theme.dart';
import 'package:pokemon_market/providers/like_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomePageList extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final VoidCallback onAddProduct;
  final Function(String?) onDelete; // String?로 변경하여 null 허용

  const HomePageList({
    super.key,
    required this.products,
    required this.onAddProduct,
    required this.onDelete,
  });

  @override
  State<HomePageList> createState() => _HomePageListState();
}

class _HomePageListState extends State<HomePageList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatCreatedAt(String? createdAt) {
    if (createdAt == null) return '알 수 없음';
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      return '알 수 없음';
    }
  }

  String formatPrice(dynamic price) {
    int priceValue;
    if (price is String) {
      priceValue = int.tryParse(price.replaceAll(',', '')) ?? 0;
    } else if (price is int) {
      priceValue = price;
    } else {
      priceValue = 0;
    }
    return NumberFormat('#,###').format(priceValue);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.products.isEmpty
            ? Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_animationController.value * 0.05),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? PokemonColors.cardDark
                          : PokemonColors.cardLight,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isDarkMode
                            ? PokemonColors.primaryBlue.withOpacity(0.2)
                            : PokemonColors.primaryRed.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/empty_pokemon.png',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 16),
                        CommonText(
                          text: '등록된 상품이 없습니다',
                          fontSize: 18,
                          textColor:
                              Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                        const SizedBox(height: 8),
                        CommonText(
                          text: '새로운 상품을 등록해보세요!',
                          fontSize: 14,
                          textColor: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: widget.onAddProduct,
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: isDarkMode
                                ? PokemonColors.primaryYellow
                                : PokemonColors.primaryRed,
                          ),
                          label: Text(
                            '상품 등록하기',
                            style: TextStyle(
                              color: isDarkMode
                                  ? PokemonColors.primaryYellow
                                  : PokemonColors.primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            side: BorderSide(
                              color: isDarkMode
                                  ? PokemonColors.primaryYellow
                                  : PokemonColors.primaryRed,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  final productId =
                      product['id']?.toString() ?? index.toString();

                  return Consumer<LikeProvider>(
                    builder: (context, likeProvider, child) {
                      final isLiked = likeProvider.isLiked(productId);
                      final likeCount = likeProvider.getLikeCount(productId);

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailPage(product: product),
                            ),
                          );

                          if (result != null &&
                              result is Map<String, dynamic>) {
                            if (result['deleted'] == true) {
                              final id = result['id']?.toString();
                              print('삭제 요청된 상품 ID: $id');
                              setState(() {
                                widget.products.removeWhere(
                                  (item) => item['id']?.toString() == id,
                                );
                              });
                              widget.onDelete(id);
                              print('삭제 후 남은 상품 수: ${widget.products.length}');
                            } else {
                              setState(() {
                                widget.products[index] = result;
                              });
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? PokemonColors.cardDark
                                : PokemonColors.cardLight,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: product['imagePath'] != null
                                          ? CommonImg(
                                              path: product['imagePath']
                                                  as String,
                                              width: double.infinity,
                                              height: 200,
                                              boxFit: BoxFit.cover,
                                            )
                                          : const CommonImg(
                                              path: 'assets/placeholder.png',
                                              width: double.infinity,
                                              height: 200,
                                              boxFit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        likeProvider.toggleLike(productId);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.black.withOpacity(0.5)
                                              : Colors.white.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? PokemonColors.primaryRed
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: CommonText(
                                            text: product['name'] ?? '이름 없음',
                                            fontSize: 18,
                                            textColor: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        CommonText(
                                          text:
                                              '${formatPrice(product['price'])}원',
                                          fontSize: 18,
                                          textColor: PokemonColors.primaryRed,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        CommonText(
                                          text: '포켓몬 센터',
                                          fontSize: 14,
                                          textColor: Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        CommonText(
                                          text: formatCreatedAt(
                                              product['createdAt']),
                                          fontSize: 14,
                                          textColor: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? PokemonColors.primaryBlue
                                                    .withOpacity(0.2)
                                                : PokemonColors.primaryBlue
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.favorite,
                                                color: PokemonColors.primaryRed,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              CommonText(
                                                text: '$likeCount',
                                                fontSize: 12,
                                                textColor: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (product['quantity'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? PokemonColors.primaryYellow
                                                      .withOpacity(0.2)
                                                  : PokemonColors.primaryYellow
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: CommonText(
                                              text:
                                                  '수량: ${product['quantity']}개',
                                              fontSize: 12,
                                              textColor: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
        Positioned(
          bottom: 56,
          right: 36,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_animationController.value * 0.1),
                child: child,
              );
            },
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          PokemonColors.primaryBlue,
                          PokemonColors.primaryBlue.withOpacity(0.8),
                        ]
                      : [
                          PokemonColors.primaryRed,
                          PokemonColors.primaryRed.withOpacity(0.8),
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? PokemonColors.primaryBlue.withOpacity(0.4)
                        : PokemonColors.primaryRed.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onAddProduct();
                    setState(() {});
                  },
                  customBorder: const CircleBorder(),
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  child: Center(
                    child: Image.asset(
                      'assets/plus_logo.png',
                      color: Colors.white,
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
