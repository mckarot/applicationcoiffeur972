import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:soifapp/models/haircut_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:soifapp/models/sub_category.dart';

class SelectServicePage extends StatefulWidget {
  final List<HaircutService> allServices;
  final List<SubCategory> allSubCategories;
  final Future<List<HaircutService>> Function() onRefresh;

  const SelectServicePage(
      {super.key,
      required this.allServices,
      required this.allSubCategories,
      required this.onRefresh});

  @override
  State<SelectServicePage> createState() => _SelectServicePageState();
}

class _SelectServicePageState extends State<SelectServicePage> {
  late List<HaircutService> _currentServices;
  ServiceCategory _selectedMainCategory =
      ServiceCategory.femme; // Catégorie par défaut
  String? _selectedSubCategoryName;

  @override
  void initState() {
    super.initState();
    _currentServices = widget.allServices;
  }

  Future<void> _handleRefresh() async {
    // Note: This only refreshes services. A more complex state management
    // would be needed to refresh both services and sub-categories from here.
    final newServices = await widget.onRefresh();
    if (mounted) {
      setState(() {
        _currentServices = newServices;
      });
    }
  }

  Widget _buildServiceImage(HaircutService service, BuildContext context) {
    final theme = Theme.of(context);

    if (service.imagePlaceholder.isNotEmpty) {
      final imageUrl = service.imagePlaceholder;
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(
              child: CircularProgressIndicator(
            strokeWidth: 2.0,
          )),
        ),
        errorWidget: (context, url, error) {
          return _buildDefaultServiceIcon(service, theme);
        },
      );
    }
    return _buildDefaultServiceIcon(service, theme);
  }

  Widget _buildDefaultServiceIcon(HaircutService service, ThemeData theme) {
    IconData iconData;
    Color baseColor;

    switch (service.category) {
      case ServiceCategory.femme:
        iconData = Icons.female_rounded;
        baseColor = Colors.pink[300]!;
        break;
      case ServiceCategory.homme:
        iconData = Icons.male_rounded;
        baseColor = Colors.blue[300]!;
        break;
      case ServiceCategory.enfant:
        iconData = Icons.child_care_rounded;
        baseColor = Colors.green[300]!;
        break;
      case ServiceCategory.mixte:
      case ServiceCategory.undefined:
        iconData = Icons.spa_rounded;
        baseColor = Colors.purple[300]!;
        break;
    }
    return Container(
        decoration: BoxDecoration(color: baseColor.withOpacity(0.15)),
        child: Center(
            child: Icon(iconData,
                color: baseColor,
                size: 50)));
  }

  final List<ServiceCategory> _displayCategories = [
    ServiceCategory.femme,
    ServiceCategory.homme,
    ServiceCategory.enfant,
    ServiceCategory.mixte,
  ];

  IconData _getDynamicIconForSubCategory(String? name) {
    final icons = [
      Icons.style_outlined,
      Icons.auto_fix_high_outlined,
      Icons.content_cut_rounded,
      Icons.brush_outlined,
      Icons.spa_outlined,
      Icons.face_retouching_natural_outlined,
      Icons.waves_outlined,
      Icons.color_lens_outlined,
      Icons.category_outlined,
    ];
    if (name == null || name.isEmpty) return Icons.interests_outlined;
    return icons[name.hashCode % icons.length];
  }

  Widget _buildSubCategoryCard(SubCategory subCategory) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget imageWidget;

    if (subCategory.imageUrl != null && subCategory.imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: subCategory.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
        ),
        errorWidget: (context, url, error) {
          final icon = _getDynamicIconForSubCategory(subCategory.name);
          return Container(
              color: colorScheme.surfaceContainer,
              child: Icon(icon, color: colorScheme.primary, size: 50));
        },
      );
    } else {
      final icon = _getDynamicIconForSubCategory(subCategory.name);
      imageWidget = Container(
          color: colorScheme.surfaceContainer,
          child: Icon(icon, color: colorScheme.primary, size: 50));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubCategoryName = subCategory.name;
          });
        },
        child: GridTile(
          footer: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Text(
              subCategory.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          child: imageWidget,
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, curve: Curves.easeIn);
  }

  Widget _buildSubCategorySelection({Key? key}) {
    final relevantSubCategories = widget.allSubCategories.where((subCat) {
      return subCat.category == _selectedMainCategory.toJson();
    }).toList();

    relevantSubCategories
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (relevantSubCategories.isEmpty) {
      return const Center(
        child: Text("Aucune prestation disponible dans cette catégorie."),
      );
    }

    return GridView.builder(
      key: key,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: relevantSubCategories.length,
      itemBuilder: (context, index) {
        final subCategory = relevantSubCategories[index];
        return _buildSubCategoryCard(subCategory);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubCategoryName ?? 'Choisir une Prestation'),
        leading: _selectedSubCategoryName != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  setState(() {
                    _selectedSubCategoryName = null;
                  });
                },
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              color: colorScheme.surfaceContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _displayCategories.map((category) {
                  final isSelected = _selectedMainCategory == category;
                  String text;
                  switch (category) {
                    case ServiceCategory.femme:
                      text = 'Femme';
                      break;
                    case ServiceCategory.homme:
                      text = 'Homme';
                      break;
                    case ServiceCategory.enfant:
                      text = 'Enfant';
                      break;
                    case ServiceCategory.mixte:
                      text = 'Mixte';
                      break;
                    case ServiceCategory.undefined:
                      text = 'Autre';
                  }
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMainCategory = category;
                        _selectedSubCategoryName = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(text,
                          style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _selectedSubCategoryName == null
                    ? _buildSubCategorySelection(
                        key: ValueKey(_selectedMainCategory.toString()))
                    : _buildServiceListForSubCategory(
                        key: ValueKey(_selectedSubCategoryName)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListForSubCategory({Key? key}) {
    final List<HaircutService> servicesToList =
        _currentServices.where((service) {
      bool subCategoryMatch = service.subCategory.trim().toLowerCase() ==
          _selectedSubCategoryName?.trim().toLowerCase();

      if (!subCategoryMatch) return false;

      bool categoryMatch = service.category == _selectedMainCategory;
      return categoryMatch;
    }).toList();

    if (servicesToList.isEmpty) {
      return const Center(
          child: Text('Aucun service pour cette sous-catégorie.'));
    }

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.all(16.0),
      itemCount: servicesToList.length,
      itemBuilder: (context, index) {
        final service = servicesToList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.pop(context, service);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: _buildServiceImage(service, context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${service.price.toStringAsFixed(2)} € - ${service.duration.inMinutes} min',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
      },
    );
  }
}