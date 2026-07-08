import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class AddTradeScreen extends StatefulWidget {
  final VoidCallback onTradeAdded;
  const AddTradeScreen({super.key, required this.onTradeAdded});

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  static const Color emerald = Color(0xFF10B981);
  final ApiService _api = ApiService.instance;
  final _formKey = GlobalKey<FormState>();
  final _numberFormat = NumberFormat('#,###');

  final _tickerController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _commissionController = TextEditingController();
  bool _isCommissionManual = false;

  String _side = 'BUY';

  bool _loadingValidation = false;
  bool _confirmSubmitting = false;
  bool _showConfirm = false;

  String? _validationError;
  int _simulatedPnl = 0;
  bool _isLoss = false;
  int _simulatedLossAmount = 0;

  Map<String, dynamic>? _successResult;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_onPriceQtyChange);
    _qtyController.addListener(_onPriceQtyChange);
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  void _onPriceQtyChange() {
    if (_isCommissionManual) {
      setState(() {});
      return;
    }
    
    final priceText = _priceController.text;
    final qtyText = _qtyController.text;
    if (priceText.isNotEmpty && qtyText.isNotEmpty) {
      final price = int.tryParse(priceText) ?? 0;
      final qty = int.tryParse(qtyText) ?? 0;
      final commission = (price * qty * 0.0047).round();
      _commissionController.text = commission.toString();
    } else {
      _commissionController.text = '0';
    }
    setState(() {});
  }

  String _friendlyError(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _startTradeSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final ticker = _tickerController.text.trim().toUpperCase();
    final price = int.parse(_priceController.text);
    final qty = int.parse(_qtyController.text);
    final commission = int.tryParse(_commissionController.text) ?? 0;

    setState(() {
      _loadingValidation = true;
      _errorMsg = null;
      _successResult = null;
      _validationError = null;
      _simulatedPnl = 0;
      _isLoss = false;
      _simulatedLossAmount = 0;
    });

    try {
      final res = await _api.initTrade(ticker, _side, price, qty, commission: commission);
      setState(() {
        _loadingValidation = false;
        _validationError = res['validationError'];
        _simulatedPnl = (res['simulatedPnl'] as num? ?? 0).toInt();
        _isLoss = res['isLoss'] == true;
        _simulatedLossAmount = (res['simulatedLossAmount'] as num? ?? 0).toInt();
        _showConfirm = true;
      });
    } catch (e) {
      setState(() {
        _loadingValidation = false;
        _errorMsg = _friendlyError(e);
      });
    }
  }

  Future<void> _confirmAndSubmitTrade() async {
    final ticker = _tickerController.text.trim().toUpperCase();
    final price = int.parse(_priceController.text);
    final qty = int.parse(_qtyController.text);
    final commission = int.tryParse(_commissionController.text) ?? 0;

    setState(() {
      _showConfirm = false;
      _confirmSubmitting = true;
    });

    try {
      final res = await _api.confirmTrade(ticker, _side, price, qty, commission: commission);
      setState(() {
        _successResult = res;
        _confirmSubmitting = false;
      });
      widget.onTradeAdded();
      _tickerController.clear();
      _priceController.clear();
      _qtyController.clear();
      _commissionController.clear();
      _isCommissionManual = false;
      _formKey.currentState?.reset();
    } catch (e) {
      setState(() {
        _confirmSubmitting = false;
        _errorMsg = _friendlyError(e);
      });
    }
  }

  void _cancelConfirm() {
    setState(() {
      _showConfirm = false;
      _validationError = null;
    });
  }

  String _sideLabel(AppLocalizations l10n, String side) => side == 'BUY' ? l10n.sideBuy : l10n.sideSell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (!_showConfirm) _buildForm(l10n) else _buildConfirmCard(l10n),

          // Error Alerts
          if (_errorMsg != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.errorPrefix(_errorMsg!),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Success Result Box
          if (_successResult != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: emerald.withOpacity(0.1),
                border: Border.all(color: emerald.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: emerald),
                      const SizedBox(width: 8),
                      Text(
                        l10n.tradeConfirmedTitle,
                        style: const TextStyle(color: emerald, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.recordedSummary(
                      '${_successResult!['trade']['qty']}',
                      '${_successResult!['trade']['ticker']}',
                      _numberFormat.format(_successResult!['trade']['price']),
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_successResult!['warning'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.warningPrefix('${_successResult!['warning']}'),
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ],
                  if (_successResult!['trade']['side'] == 'SELL' &&
                      _successResult!['allocations'] != null &&
                      (_successResult!['allocations'] as List).isNotEmpty) ...[
                    const Divider(color: emerald, height: 24),
                    Text(
                      l10n.lifoMatchedLots,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...(_successResult!['allocations'] as List).map((a) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '• ${l10n.matchedLotLine('${a['qtyAllocated']}', _numberFormat.format(a['buyPrice']))}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Text(
                      l10n.realisedProfitLossLabel(
                        '${_successResult!['realisedPnl'] >= 0 ? '+' : ''}${_numberFormat.format(_successResult!['realisedPnl'])}',
                      ),
                      style: TextStyle(
                        color: _successResult!['realisedPnl'] >= 0 ? emerald : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Card(
      color: const Color(0xFF151B2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF24304F)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.recordNewTrade,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Ticker Field
              TextFormField(
                controller: _tickerController,
                decoration: InputDecoration(
                  labelText: l10n.tickerSymbolLabel,
                  hintText: l10n.tickerSymbolHint,
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF24304F))),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v == null || v.trim().isEmpty ? l10n.tickerRequired : null,
              ),
              const SizedBox(height: 20),

              // Side Toggles
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _side = 'BUY'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _side == 'BUY' ? emerald.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(color: _side == 'BUY' ? emerald : const Color(0xFF24304F)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.sideBuy,
                          style: TextStyle(
                            color: _side == 'BUY' ? emerald : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _side = 'SELL'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _side == 'SELL' ? Colors.redAccent.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(color: _side == 'SELL' ? Colors.redAccent : const Color(0xFF24304F)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.sideSell,
                          style: TextStyle(
                            color: _side == 'SELL' ? Colors.redAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: l10n.pricePerShareRielLabel,
                  hintText: l10n.pricePerShareHint,
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF24304F))),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.priceRequired;
                  final val = int.tryParse(v);
                  if (val == null || val <= 0) return l10n.invalidPrice;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantity Field
              TextFormField(
                controller: _qtyController,
                decoration: InputDecoration(
                  labelText: l10n.quantitySharesLabel,
                  hintText: l10n.quantityHint,
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF24304F))),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.quantityRequired;
                  final val = int.tryParse(v);
                  if (val == null || val <= 0) return l10n.invalidQuantity;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Commission Field
              TextFormField(
                controller: _commissionController,
                decoration: const InputDecoration(
                  labelText: 'Commission Fee (riel)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF24304F))),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  setState(() {
                    _isCommissionManual = true;
                  });
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Commission is required';
                  final val = int.tryParse(v);
                  if (val == null || val < 0) return 'Invalid commission';
                  return null;
                },
              ),

              // Live Total Price Preview
              Builder(
                builder: (context) {
                  final price = int.tryParse(_priceController.text) ?? 0;
                  final qty = int.tryParse(_qtyController.text) ?? 0;
                  if (price > 0 && qty > 0) {
                    final subtotal = price * qty;
                    final commission = int.tryParse(_commissionController.text) ?? 0;
                    final total = _side == 'BUY' ? (subtotal + commission) : (subtotal - commission);
                    final totalColor = _side == 'BUY' ? Colors.redAccent : emerald;

                    return Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1422),
                        border: Border.all(color: const Color(0xFF24304F)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text('${_numberFormat.format(subtotal)} riel', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Commission:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text('${_numberFormat.format(commission)} riel', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const Divider(color: Color(0xFF24304F), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Total:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '${_numberFormat.format(total)} riel',
                                style: TextStyle(color: totalColor, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _loadingValidation ? null : _startTradeSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _side == 'BUY' ? emerald : Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loadingValidation
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        l10n.confirmSide(_sideLabel(l10n, _side)),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmCard(AppLocalizations l10n) {
    return Card(
      color: const Color(0xFF151B2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF24304F)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _validationError != null ? l10n.validationErrorTitle : l10n.confirmTransactionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Color(0xFF24304F), height: 30),

            if (_validationError != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.validationFailedPrefix(_validationError!),
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.adjustParametersHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cancelConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B5563),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l10n.returnToEdit, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              _confirmRow(l10n.stockTickerLabel, _tickerController.text.trim().toUpperCase(), valueColor: const Color(0xFF60A5FA)),
              _confirmRow(l10n.actionLabel, _sideLabel(l10n, _side), valueColor: _side == 'BUY' ? emerald : Colors.redAccent),
              _confirmRow(l10n.quantityRowLabel, l10n.quantityValue(_numberFormat.format(int.tryParse(_qtyController.text) ?? 0))),
              _confirmRow(l10n.pricePerShareValueLabel, '${_numberFormat.format(int.tryParse(_priceController.text) ?? 0)} riel'),
              _confirmRow(
                l10n.estimatedTotalLabel,
                '${_numberFormat.format((int.tryParse(_qtyController.text) ?? 0) * (int.tryParse(_priceController.text) ?? 0))} riel',
                bold: true,
              ),

              if (_side == 'SELL') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF24304F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _confirmRow(
                        l10n.simulatedPnlLabel,
                        '${_simulatedPnl >= 0 ? '+' : ''}${_numberFormat.format(_simulatedPnl)} riel',
                        valueColor: _simulatedPnl >= 0 ? emerald : Colors.redAccent,
                        bold: true,
                      ),
                      if (_isLoss) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.1),
                            border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.sellLossWarningTitle,
                                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.sellLossWarningBody(_numberFormat.format(_simulatedLossAmount)),
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmSubmitting ? null : _cancelConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF374151),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l10n.cancel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirmSubmitting ? null : _confirmAndSubmitTrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _side == 'BUY' ? emerald : Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _confirmSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(l10n.yesSubmitTrade, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 0.5)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}