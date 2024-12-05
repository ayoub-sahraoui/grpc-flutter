import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'generated/compte.pbenum.dart';
import 'providers/compte_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CompteProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TypeCompte? _selectedFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<CompteProvider>(context, listen: false).loadComptes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        actions: [
          PopupMenuButton<TypeCompte?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (TypeCompte? value) {
              setState(() => _selectedFilter = value);
              if (value == null) {
                Provider.of<CompteProvider>(context, listen: false)
                    .resetFilters();
              } else {
                Provider.of<CompteProvider>(context, listen: false)
                    .filterComptesByType(value);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<TypeCompte?>(
                value: null,
                child: Text('All Accounts'),
              ),
              ...TypeCompte.values.map(
                (type) => PopupMenuItem<TypeCompte>(
                  value: type,
                  child: Text(type.name),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<CompteProvider>(context, listen: false).loadComptes();
            },
          ),
        ],
      ),
      body: Consumer<CompteProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadComptes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final accounts = _selectedFilter == null
              ? provider.comptes
              : provider.filteredComptes;

          return Column(
            children: [
              // Stats Card
              if (provider.stats != null)
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Total Accounts: ${provider.stats!.count}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Balance: ${provider.stats!.sum.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Average Balance: ${provider.stats!.average.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),

              // Filter Indicator
              if (_selectedFilter != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text('Filtered by: ${_selectedFilter!.name}'),
                    onDeleted: () {
                      setState(() => _selectedFilter = null);
                      provider.resetFilters();
                    },
                  ),
                ),

              // Accounts List
              Expanded(
                child: accounts.isEmpty
                    ? const Center(
                        child: Text('No accounts found'),
                      )
                    : ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final compte = accounts[index];
                          return Dismissible(
                            key: Key(compte.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Account'),
                                content: const Text(
                                    'Are you sure you want to delete this account?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (direction) {
                              provider.deleteCompte(compte.id);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text('Account ID: ${compte.id}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Balance: ${compte.solde.toStringAsFixed(2)}'),
                                    Text('Created: ${compte.dateCreation}'),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(compte.type.name),
                                  backgroundColor:
                                      compte.type == TypeCompte.COURANT
                                          ? Colors.blue[100]
                                          : Colors.green[100],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    double solde = 0;
    TypeCompte type = TypeCompte.COURANT;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Balance',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => solde = double.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TypeCompte>(
              value: type,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                prefixIcon: Icon(Icons.account_balance),
              ),
              items: TypeCompte.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => type = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (solde > 0) {
                Provider.of<CompteProvider>(context, listen: false).saveCompte(
                  solde,
                  DateTime.now().toIso8601String(),
                  type,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid balance'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
