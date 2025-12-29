// New methods for cotton sales screen - to be integrated back into main file

Widget _buildBuyerNameInput() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: _buyerNameController.text),
        optionsBuilder: (TextEditingValue textEditingValue) async {
          try {
            // Get all buyer names from existing buyers
            final allBuyerNames = buyers.map((b) => b.name).toList();
            
            // If input is empty, return all buyers
            if (textEditingValue.text.isEmpty) {
              return allBuyerNames;
            }
            
            // Filter buyers based on input
            final query = textEditingValue.text.toLowerCase();
            return allBuyerNames.where((buyer) => 
              buyer.toLowerCase().contains(query)).toList();
          } catch (e) {
            return <String>[];
          }
        },
        onSelected: (String selection) {
          _buyerNameController.text = selection;
          selectedBuyerName = selection;
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          // Sync with our main controller
          fieldTextEditingController.addListener(() {
            _buyerNameController.text = fieldTextEditingController.text;
            selectedBuyerName = fieldTextEditingController.text;
          });
          
          return TextFormField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            decoration: const InputDecoration(
              labelText: 'Номи харидор',
              prefixIcon: Icon(Icons.person),
              suffixIcon: Icon(Icons.arrow_drop_down),
              hintText: 'Номи харидорро ворид кунед',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Номи харидор зарур аст';
              }
              return null;
            },
            onFieldSubmitted: (value) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, 
                              color: Colors.blue, 
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildSaleItemsList() {
  if (saleItems.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ҳеҷ дастаи фуруш илова нашудааст',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Барои илова кардани дастаи нав тугмаи "+" -ро пахш кунед',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    children: saleItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _buildSaleItemCard(item, index);
    }).toList(),
  );
}

Widget _buildSaleItemCard(SaleItem item, int index) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Дастаи ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () => _removeSaleItem(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Хориҷ кардан',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.weightController,
                  decoration: const InputDecoration(
                    labelText: 'Вазни як дона (кг)',
                    suffixText: 'кг',
                    hintText: '10, 15, 20...',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => _validateWeight(value),
                  onChanged: (value) => _updateSaleItem(index),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: item.piecesController,
                  decoration: const InputDecoration(
                    labelText: 'Адад',
                    suffixText: 'дона',
                    hintText: 'Шумора',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validatePieces(value),
                  onChanged: (value) => _updateSaleItem(index),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildItemSummary(item),
          _buildWarehouseValidation(item),
        ],
      ),
    ),
  );
}

Widget _buildItemSummary(SaleItem item) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ҳамагӣ:',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${item.pieces} × ${item.weight.toStringAsFixed(1)} = ${item.totalWeight.toStringAsFixed(1)} кг',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _buildWarehouseValidation(SaleItem item) {
  return Consumer<CottonWarehouseProvider>(
    builder: (context, warehouseProvider, _) {
      final inventory = warehouseProvider.processedCottonInventory;
      
      // Find matching inventory for this weight
      final matchingBatches = inventory.where((batch) => 
        (batch.weightPerPiece - item.weight).abs() <= 0.1).toList();
      
      if (matchingBatches.isEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Дар анбор вазни ${item.weight.toStringAsFixed(1)} кг мавҷуд нест',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      
      final availablePieces = matchingBatches.fold<int>(0, (sum, batch) => sum + batch.pieces);
      
      if (item.pieces > availablePieces) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Дар анбор кофӣ нест!',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Мавҷуд: $availablePieces дона, дархост: ${item.pieces} дона',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }
      
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Дар анбор мавҷуд: $availablePieces дона',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildAddItemButton() {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _addSaleItem,
      icon: const Icon(Icons.add),
      label: const Text('Илова кардани дастаи нав'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    ),
  );
}

Widget _buildSaleSummary() {
  final totalPieces = saleItems.fold<int>(0, (sum, item) => sum + item.pieces);
  final totalWeight = saleItems.fold<double>(0, (sum, item) => sum + item.totalWeight);
  
  return Card(
    color: Colors.green.withOpacity(0.1),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ҷамъбасти фуруш',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Ҷамъи донаҳо', '$totalPieces дона'),
          const SizedBox(height: 8),
          _buildSummaryRow('Ҷамъи вазн', '${totalWeight.toStringAsFixed(1)} кг'),
        ],
      ),
    ),
  );
}

Widget _buildSummaryRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

Widget _buildFormActionButtons() {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _cancelSaleForm,
          child: const Text('Бекор кардан'),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton(
          onPressed: saleItems.isNotEmpty ? _saveSale : null,
          child: const Text('Сабт кардан'),
        ),
      ),
    ],
  );
}

Widget _buildBuyerSalesCard(String buyerName, List<CottonStockSale> sales) {
  final totalWeight = sales.fold<double>(0, (sum, sale) => sum + sale.totalWeight);
  final totalPieces = sales.fold<int>(0, (sum, sale) => sum + sale.units);
  final latestDate = sales.map((s) => s.saleDate).reduce((a, b) => a.isAfter(b) ? a : b);
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person, color: Colors.blue, size: 20),
      ),
      title: Text(
        buyerName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'Охирин харид: ${DateFormat('dd/MM/yyyy').format(latestDate)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${sales.length} фуруш',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.green,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$totalPieces',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'дона',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    Column(
                      children: [
                        Text(
                          '${totalWeight.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'кг',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...sales.map((sale) => _buildIndividualSaleItem(sale)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildIndividualSaleItem(CottonStockSale sale) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(sale.saleDate),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${sale.units} × ${sale.unitWeight.toStringAsFixed(1)}кг',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Text(
          '${sale.totalWeight.toStringAsFixed(1)} кг',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    ),
  );
}
