import 'dart:math';

enum LoanMethod { declining, flat }
enum RatePeriod { month, year }

const int maxTermMonths = 480;

class LoanInput {
  final double amount;
  final String currency; // 'USD' or 'KHR'
  final double ratePct;
  final RatePeriod ratePeriod;
  final int termMonths;
  final LoanMethod method;
  final String startDate; // YYYY-MM-DD

  LoanInput({
    required this.amount,
    required this.currency,
    required this.ratePct,
    required this.ratePeriod,
    required this.termMonths,
    required this.method,
    required this.startDate,
  });
}

class ScheduleRow {
  final int no;
  final String date;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  ScheduleRow({
    required this.no,
    required this.date,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

class LoanSchedule {
  final List<ScheduleRow> rows;
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
  final double otherMethodTotalInterest;

  LoanSchedule({
    required this.rows,
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.otherMethodTotalInterest,
  });
}

double _roundMoney(double value, String currency) {
  return currency == 'USD' ? (value * 100).round() / 100 : value.roundToDouble();
}

double _monthlyRate(LoanInput input) {
  return input.ratePeriod == RatePeriod.month ? input.ratePct / 100 : input.ratePct / 1200;
}

String _addMonths(String isoDate, int months) {
  final parts = isoDate.split('-').map(int.parse).toList();
  int y = parts[0];
  int m = parts[1];
  int d = parts[2];

  int totalMonths = (m - 1) + months;
  int year = y + (totalMonths ~/ 12);
  int month = (totalMonths % 12) + 1;

  int daysInMonth = DateTime(year, month + 1, 0).day;
  int day = d < daysInMonth ? d : daysInMonth;

  return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
}

double _emiPayment(double principal, double r, int n) {
  if (r == 0) return principal / n;
  return (principal * r) / (1 - pow(1 + r, -n));
}

double _totalInterestFor(LoanInput input, LoanMethod method) {
  final r = _monthlyRate(input);
  final n = input.termMonths;
  if (method == LoanMethod.flat) return _roundMoney(input.amount * r * n, input.currency);
  return _roundMoney(_emiPayment(input.amount, r, n) * n - input.amount, input.currency);
}

LoanSchedule buildSchedule(LoanInput input) {
  final currency = input.currency;
  final int n = input.termMonths.clamp(1, maxTermMonths);
  final double p = input.amount;
  final double r = _monthlyRate(input);

  final List<ScheduleRow> rows = [];
  double balance = p;
  double totalInterest = 0;

  final double flatInterest = _roundMoney(p * r, currency);
  final double flatPrincipal = _roundMoney(p / n, currency);
  final double emi = _roundMoney(_emiPayment(p, r, n), currency);

  for (int i = 1; i <= n; i++) {
    bool last = i == n;
    double interest;
    double principal;

    if (input.method == LoanMethod.flat) {
      interest = flatInterest;
      principal = last ? balance : flatPrincipal;
    } else {
      interest = _roundMoney(balance * r, currency);
      principal = last ? balance : _roundMoney(emi - interest, currency);
    }

    double payment = _roundMoney(principal + interest, currency);
    balance = _roundMoney(balance - principal, currency);
    totalInterest = _roundMoney(totalInterest + interest, currency);

    rows.add(ScheduleRow(
      no: i,
      date: _addMonths(input.startDate, i),
      payment: payment,
      principal: principal,
      interest: interest,
      balance: balance,
    ));
  }

  double totalPayment = _roundMoney(p + totalInterest, currency);
  double monthlyPayment = input.method == LoanMethod.flat ? _roundMoney(flatPrincipal + flatInterest, currency) : emi;
  LoanMethod otherMethod = input.method == LoanMethod.flat ? LoanMethod.declining : LoanMethod.flat;

  return LoanSchedule(
    rows: rows,
    monthlyPayment: monthlyPayment,
    totalPayment: totalPayment,
    totalInterest: totalInterest,
    otherMethodTotalInterest: _totalInterestFor(input, otherMethod),
  );
}
