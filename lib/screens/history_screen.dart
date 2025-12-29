import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_history.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  int? _selectedYear;
  int? _selectedMonth;
  String? _selectedCurrency;
  TransactionCategory? _selectedCategory;
  
  // Cache filtered lists to prevent constant rebuilds
  List<TransactionHistory> _moneyHistory = [];
  List<TransactionHistory> _goodsHistory = [];
  List<TransactionHistory> _stockHistory = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllHistoryOnce();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHistoryOnce() async {
    if (_dataLoaded) return;
    
    await context.read<HistoryProvider>().loadAllHistory();
    _updateFilteredLists();
    setState(() => _dataLoaded = true);
  }
  
  void _onTabChanged() {
    // Update category filter based on current tab
    TransactionCategory? newCategory;
    switch (_tabController.index) {
      case 0: newCategory = TransactionCategory.money; break;
      case 1: newCategory = TransactionCategory.goods; break;
      case 2: newCategory = TransactionCategory.stock; break;
      case 3: newCategory = null; break; // Summary tab
    }
    
    if (newCategory != _selectedCategory) {
      setState(() => _selectedCategory = newCategory);
      _updateFilteredLists();
    }
  }
  
  void _updateFilteredLists() {
    final provider = context.read<HistoryProvider>();
    final allHistory = provider.allHistory;
    
    // Apply current filters to all data
    List<TransactionHistory> filtered = allHistory.where((history) {
      // Year filter
      if (_selectedYear != null && history.date.year != _selectedYear) {
        return false;
      }
      
      // Month filter
      if (_selectedMonth != null && history.date.month != _selectedMonth) {
        return false;
      }
      
      // Search filter
      final searchQuery = _searchController.text.trim().toLowerCase();
      if (searchQuery.isNotEmpty) {
        if (!history.description.toLowerCase().contains(searchQuery) &&
            !history.personName.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }
      
      // Currency filter
      if (_selectedCurrency != null && history.currency != _selectedCurrency) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Split into category lists
    _moneyHistory = filtered.where((h) => h.category == TransactionCategory.money).toList();
    _goodsHistory = filtered.where((h) => h.category == TransactionCategory.goods).toList();
    _stockHistory = filtered.where((h) => h.category == TransactionCategory.stock).toList();
    
    setState(() {});
  }
  
  void _applyFiltersDebounced() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateFilteredLists();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
      _selectedCurrency = null;
      _selectedCategory = null;
      _searchController.clear();
    });
    _updateFilteredLists();
  }

  Widget _buildFilterSection() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 1,
            child: ExpansionTile(
              leading: const Icon(Icons.filter_list, size: 20),
              title: const Text(
                'Филтрҳо',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Пок кардан', style: TextStyle(fontSize: 12)),
                  ),
                  const Icon(Icons.expand_more),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Search Bar - Compact
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ҷустуҷӯ ба ном...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _updateFilteredLists();
                              },
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) => _applyFiltersDebounced(),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Compact Filter Grid
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: DropdownButtonFormField<int>(
                                value: _selectedYear,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Year',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('All'),
                                  ),
                                  ...provider.availableYears.map((year) =>
                                    DropdownMenuItem<int>(
                                      value: year,
                                      child: Text(year.toString()),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedYear = value;
                                    if (value == null) _selectedMonth = null;
                                  });
                                  _updateFilteredLists();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: DropdownButtonFormField<int>(
                                value: _selectedMonth,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Month',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('All'),
                                  ),
                                  if (_selectedYear != null)
                                    ...List.generate(12, (index) => index + 1).map((month) =>
                                      DropdownMenuItem<int>(
                                        value: month,
                                        child: Text(_getMonthName(month).substring(0, 3)),
                                      ),
                                    ),
                                ],
                                onChanged: _selectedYear != null ? (value) {
                                  setState(() {
                                    _selectedMonth = value;
                                  });
                                  _updateFilteredLists();
                                } : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: DropdownButtonFormField<TransactionCategory>(
                                value: _selectedCategory,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                items: [
                                  const DropdownMenuItem<TransactionCategory>(
                                    value: null,
                                    child: Text('All'),
                                  ),
                                  ...TransactionCategory.values.map((category) =>
                                    DropdownMenuItem<TransactionCategory>(
                                      value: category,
                                      child: Text(category.name.substring(0, 1).toUpperCase() + category.name.substring(1)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                  _updateFilteredLists();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrency,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Ҳама асъорҳо'),
                                  ),
                                  ...provider.availableCurrencies.map((currency) =>
                                    DropdownMenuItem<String>(
                                      value: currency,
                                      child: Text(currency),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCurrency = value;
                                  });
                                  _updateFilteredLists();
                                },
                              ),
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
  }

  Widget _buildHistoryList(List<TransactionHistory> historyList) {
    if (!_dataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transaction history found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedYear != null || _selectedMonth != null ||
                _selectedCurrency != null || _searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters to see all transactions'),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final history = historyList[index];
        return _buildHistoryTile(history, key: ValueKey('${history.id}_${history.date}_$index'));
      },
    );
  }

  Widget _buildHistoryTile(TransactionHistory history, {Key? key}) {
    Color getTypeColor(TransactionType type) {
      switch (type) {
        case TransactionType.moneyGiven:
          return Colors.red;
        case TransactionType.moneyReceived:
          return Colors.green;
        case TransactionType.moneyPaid:
          return Colors.blue;
        case TransactionType.goodsSold:
          return Colors.green;
        case TransactionType.goodsPurchased:
          return Colors.orange;
        case TransactionType.stockProcessed:
          return Colors.purple;
        case TransactionType.stockDispatched:
          return Colors.indigo;
        case TransactionType.activity:
          return Colors.grey;
      }
    }

    IconData getTypeIcon(TransactionType type) {
      switch (type) {
        case TransactionType.moneyGiven:
          return Icons.arrow_upward;
        case TransactionType.moneyReceived:
          return Icons.arrow_downward;
        case TransactionType.moneyPaid:
          return Icons.payment;
        case TransactionType.goodsSold:
          return Icons.sell;
        case TransactionType.goodsPurchased:
          return Icons.shopping_cart;
        case TransactionType.stockProcessed:
          return Icons.settings;
        case TransactionType.stockDispatched:
          return Icons.local_shipping;
        case TransactionType.activity:
          return Icons.work;
      }
    }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: () {
            // Show detailed view on tap (optional)
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon with type indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: getTypeColor(history.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getTypeIcon(history.type),
                    color: getTypeColor(history.type),
                    size: 18,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Main content - takes available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description with smaller font for mobile
                      Text(
                        history.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Person and date row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              history.personName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            _formatDate(history.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      // Notes if present
                      if (history.notes != null && history.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          history.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Amount and quantity column - optimized for mobile
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Amount
                    if (history.amount != null)
                      Text(
                        '${history.amount!.toStringAsFixed(0)} ${history.currency ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: getTypeColor(history.type),
                        ),
                      ),
                    
                    // Quantity if present
                    if (history.quantity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${history.quantity!.toStringAsFixed(1)} ${history.quantityUnit ?? ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 4),
                    
                    // Type badge - compact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: getTypeColor(history.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        history.typeDisplayName,
                        style: TextStyle(
                          fontSize: 9,
                          color: getTypeColor(history.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              _buildSummaryCard('Муомилоти пул', TransactionCategory.money),
              const SizedBox(height: 8),
              _buildSummaryCard('Муомилоти мол', TransactionCategory.goods),
              const SizedBox(height: 8),
              _buildSummaryCard('Муомилоти анбор', TransactionCategory.stock),
              const SizedBox(height: 8),
              _buildSummaryCard('Фаъолиятҳо', TransactionCategory.activity),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, TransactionCategory category) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        final categoryHistory = provider.filteredHistory
            .where((h) => h.category == category)
            .toList();

        final totalTransactions = categoryHistory.length;
        final totalAmount = categoryHistory
            .where((h) => h.amount != null)
            .fold(0.0, (sum, h) => sum + h.amount!);

        final currencyBreakdown = <String, double>{};
        for (final h in categoryHistory.where((h) => h.amount != null && h.currency != null)) {
          currencyBreakdown[h.currency!] = (currencyBreakdown[h.currency!] ?? 0) + h.amount!;
        }

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row - more compact
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getCategoryIcon(category), 
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Stats row - mobile optimized
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Шумора',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalTransactions.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalAmount > 0)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Арзиш умумӣ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalAmount.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Currency breakdown - compact
                if (currencyBreakdown.isNotEmpty && currencyBreakdown.length > 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тибқи асъор:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: currencyBreakdown.entries.map((entry) =>
                            Text(
                              '${entry.key}: ${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.money:
        return Icons.account_balance_wallet;
      case TransactionCategory.goods:
        return Icons.inventory;
      case TransactionCategory.stock:
        return Icons.warehouse;
      case TransactionCategory.activity:
        return Icons.work;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Январ', 'Феврал', 'Март', 'Апрел', 'Май', 'Июн',
      'Июл', 'Август', 'Сентябр', 'Октябр', 'Ноябр', 'Декабр'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тарих', style: TextStyle(fontSize: 18)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 16),
                      SizedBox(width: 4),
                      Text('Пул'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory, size: 16),
                      SizedBox(width: 4),
                      Text('Мол'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warehouse, size: 16),
                      SizedBox(width: 4),
                      Text('Анбор'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics, size: 16),
                      SizedBox(width: 4),
                      Text('Хулоса'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(_moneyHistory),
                _buildHistoryList(_goodsHistory),
                _buildHistoryList(_stockHistory),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
