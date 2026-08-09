import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_formations/Models/formation.dart';
import 'package:gestion_formations/Models/payment.dart';
import 'package:gestion_formations/Services/db_services.dart';
import 'package:gestion_formations/config/theme.dart';

class InscriptionPage extends StatefulWidget {
  final String? formationId;

  const InscriptionPage({super.key, this.formationId});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final LocalDataService _db = LocalDataService();
  Formation? _formation;
  int currentStep = 0;
  bool _isSubmitting = false;
  final Set<String> _selectedModules = {};
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedPaymentMethod = 'virement';

  @override
  void initState() {
    super.initState();
    if (widget.formationId != null && widget.formationId!.isNotEmpty) {
      _formation = _db.getFormationById(widget.formationId!);
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final formationTitle = _formation?.titre ?? 'Formation';
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inscription à $formationTitle',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 32),

          // Stepper
          if (isMobile)
            _buildMobileStepper(context)
          else
            _buildDesktopStepper(context),
        ],
      ),
    );
  }

  Widget _buildMobileStepper(BuildContext context) {
    return Stepper(
      currentStep: currentStep,
      onStepContinue: () {
        if (currentStep < 2) {
          setState(() => currentStep += 1);
          return;
        }
        _submitInscription();
      },
      onStepCancel: () {
        if (currentStep > 0) {
          setState(() => currentStep -= 1);
        }
      },
      steps: _getSteps(),
    );
  }

  Widget _buildDesktopStepper(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: List.generate(
              _getSteps().length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: AppPadding.lg),
                child: Row(
                  children: [
                    // Step indicator
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: index <= currentStep ? AppTheme.primary : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: index <= currentStep ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
_getSteps()[index].title.toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
_getSteps()[index].subtitle?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppPadding.xl),
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(AppPadding.lg),
              child: _buildStepContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (currentStep) {
      case 0:
        return _buildSelectFormation(context);
      case 1:
        return _buildPersonalInfo(context);
      case 2:
        return _buildPayment(context);
      case 3:
        return _buildConfirmation(context);
      default:
        return SizedBox();
    }
  }

  Widget _buildSelectFormation(BuildContext context) {
    if (_formation != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formation sélectionnée',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Card(
            margin: EdgeInsets.only(bottom: AppPadding.md),
            child: Padding(
              padding: EdgeInsets.all(AppPadding.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formation!.titre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(_formation!.description),
                  SizedBox(height: 12),
                  // If the formation has modules, allow the user to select which modules to register for
                  if (_formation!.modules.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sélectionnez les modules', style: Theme.of(context).textTheme.bodyLarge),
                        SizedBox(height: 8),
                        ..._formation!.modules.map((m) => CheckboxListTile(
                              title: Text(m),
                              value: _selectedModules.contains(m),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    if (_formation!.maxModulesParEtudiant != null && _selectedModules.length >= _formation!.maxModulesParEtudiant!) {
                                      // respect the max selection
                                      return;
                                    }
                                    _selectedModules.add(m);
                                  } else {
                                    _selectedModules.remove(m);
                                  }
                                });
                              },
                            ))
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _formation!.modules
                          .map((m) => Chip(label: Text(m), backgroundColor: AppTheme.surfaceVariant))
                          .toList(),
                    ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Prix', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${(_formation!.type == FormationType.enligne ? _formation!.prixEnLigne ?? _formation!.prix : _formation!.prix).toStringAsFixed(0)} F CFA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Ce formulaire utilise la formation reçue via le lien partagé.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    final formations = _db.getFormations();

    if (formations.isEmpty) {
      return Center(child: Text('Aucune formation disponible.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez une formation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        ListView.builder(
          itemCount: formations.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final f = formations[index];
            return Card(
              margin: EdgeInsets.only(bottom: AppPadding.md),
              child: ListTile(
                title: Text(f.titre),
                subtitle: Text(f.description),
                trailing: Text(
                  '${(f.type == FormationType.enligne ? f.prixEnLigne ?? f.prix : f.prix).toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                ),
                onTap: () {
                  setState(() {
                    _formation = f;
                    currentStep = 1;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations Personnelles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _prenomController,
          decoration: InputDecoration(labelText: 'Prénom'),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _nomController,
          decoration: InputDecoration(labelText: 'Nom'),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 12),
        TextField(
          controller: _telephoneController,
          decoration: InputDecoration(labelText: 'Téléphone'),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(labelText: 'Message (optionnel)'),
          maxLines: 2,
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => currentStep -= 1),
              child: Text('Retour'),
            ),
            FilledButton(
              onPressed: () => setState(() => currentStep += 1),
              child: Text('Suivant'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayment(BuildContext context) {
    final selectedFormation = _formation;
    final amount = selectedFormation == null
        ? 0
        : selectedFormation.type == FormationType.enligne
            ? selectedFormation.prixEnLigne ?? selectedFormation.prix
            : selectedFormation.prix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paiement',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          color: AppTheme.surfaceVariant,
          child: Padding(
            padding: EdgeInsets.all(AppPadding.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé de l\'inscription'),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Formation'),
                    Text(selectedFormation?.titre ?? 'Aucune'),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prix', style: Theme.of(context).textTheme.titleMedium),
                    Text('${amount.toStringAsFixed(0)} F CFA', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Text('Méthode de paiement', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(label: Text('Carte'), value: 'carte', icon: Icon(Icons.credit_card)),
            ButtonSegment(label: Text('Virement'), value: 'virement', icon: Icon(Icons.account_balance)),
          ],
          selected: {_selectedPaymentMethod},
          onSelectionChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value.first;
            });
          },
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => currentStep -= 1),
              child: Text('Retour'),
            ),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitInscription,
              child: _isSubmitting ? CircularProgressIndicator(color: Colors.white) : Text('Confirmer l\'inscription'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 64, color: AppTheme.success),
        SizedBox(height: 16),
        Text(
          'Inscription confirmée!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.success,
              ),
        ),
        SizedBox(height: 8),
        Text(
          'Votre inscription a été créée avec succès.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 8),
        Text(
          'En attente de validation par l\'administrateur.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.warning,
              ),
        ),
        SizedBox(height: 24),
        FilledButton(
          onPressed: () {},
          child: Text('Aller au Dashboard'),
        ),
      ],
    );
  }

  Future<void> _submitInscription() async {
    if (_formation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une formation.')));
      return;
    }

    if (_prenomController.text.isEmpty || _nomController.text.isEmpty || _emailController.text.isEmpty || _telephoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez compléter toutes les informations personnelles.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = _formation!.type == FormationType.enligne ? _formation!.prixEnLigne ?? _formation!.prix : _formation!.prix;
      await _db.createInscription(
        etudiantId: 'web_${DateTime.now().millisecondsSinceEpoch}',
        formationId: _formation!.id,
        montant: amount,
        methode: _selectedPaymentMethod == 'virement' ? PaymentMethod.virement : PaymentMethod.carte,
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        description: _descriptionController.text.trim(),
        modules: _selectedModules.isNotEmpty ? _selectedModules.toList() : _formation!.modules,
        typeFormation: _formation!.type.toString().split('.').last,
      );
      setState(() {
        currentStep = 3;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'inscription : $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: Text('Sélectionner'),
        subtitle: Text('une formation'),
        content: SizedBox(),
      ),
      Step(
        title: Text('Informations'),
        subtitle: Text('personnelles'),
        content: SizedBox(),
      ),
      Step(
        title: Text('Paiement'),
        subtitle: Text('paiement'),
        content: SizedBox(),
      ),
      Step(
        title: Text('Confirmation'),
        subtitle: Text('validation'),
        content: SizedBox(),
      ),
    ];
  }
}
