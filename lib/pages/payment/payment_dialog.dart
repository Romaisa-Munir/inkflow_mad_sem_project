import 'package:flutter/material.dart';
import 'package:inkflow_mad_sem_project/services/payment_service.dart';

class PaymentDialog extends StatefulWidget {
  final String chapterTitle;
  final double price;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onNavigateToProfile;

  const PaymentDialog({
    Key? key,
    required this.chapterTitle,
    required this.price,
    required this.onPaymentSuccess,
    required this.onNavigateToProfile,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  bool _paymentComplete = false;
  late AnimationController _bounceController;
  late AnimationController _checkController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _checkController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if user has payment info
      final hasPaymentInfo = await PaymentService.hasCompletePaymentInfo();

      if (!hasPaymentInfo) {
        Navigator.pop(context);
        widget.onNavigateToProfile();
        return;
      }

      // Simulate payment processing delay
      await Future.delayed(Duration(seconds: 2));

      // Start success animation
      setState(() {
        _paymentComplete = true;
        _isProcessing = false;
      });

      _bounceController.forward();
      await Future.delayed(Duration(milliseconds: 300));
      _checkController.forward();

      // Wait for animation to complete
      await Future.delayed(Duration(seconds: 2));

      // Close dialog and trigger success callback
      Navigator.pop(context);
      widget.onPaymentSuccess();

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_paymentComplete) ..._buildPaymentContent(),
                if (_paymentComplete) ..._buildSuccessContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPaymentContent() {
    return [
      // Header
      Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payment,
              color: Colors.orange[700],
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Chapter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Secure Demo Payment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      SizedBox(height: 24),

      // Chapter Details Card
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.book,
                  color: Colors.deepPurple,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapter Title:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.chapterTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PKR ${widget.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      SizedBox(height: 20),

      // Demo Notice
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This is a demo payment. No real money will be charged.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      ),

      SizedBox(height: 24),

      // Action Buttons
      Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processPayment,
              icon: _isProcessing
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(Icons.payment),
              label: Text(
                _isProcessing
                    ? 'Processing Payment...'
                    : 'Pay PKR ${widget.price.toStringAsFixed(0)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSuccessContent() {
    return [
      // Success Animation
      ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: CheckmarkPainter(_checkAnimation.value),
                child: Container(),
              );
            },
          ),
        ),
      ),

      SizedBox(height: 24),

      // Success Message
      Text(
        'Payment Successful!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
        textAlign: TextAlign.center,
      ),

      SizedBox(height: 12),

      Container(
        width: double.infinity,
        child: Text(
          'Chapter "${widget.chapterTitle}" has been unlocked and added to your library.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      SizedBox(height: 24),

      // Success Details
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount Paid:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'PKR ${widget.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      SizedBox(height: 20),

      Text(
        'You can now start reading immediately!',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

// Custom painter for animated checkmark
class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final checkPath = Path();

    // Define checkmark path
    final startPoint = Offset(center.dx - 12, center.dy);
    final middlePoint = Offset(center.dx - 4, center.dy + 8);
    final endPoint = Offset(center.dx + 12, center.dy - 8);

    if (progress > 0) {
      checkPath.moveTo(startPoint.dx, startPoint.dy);

      if (progress <= 0.5) {
        // First half: draw to middle point
        final currentPoint = Offset.lerp(startPoint, middlePoint, progress * 2)!;
        checkPath.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Second half: draw to end point
        checkPath.lineTo(middlePoint.dx, middlePoint.dy);
        final currentPoint = Offset.lerp(middlePoint, endPoint, (progress - 0.5) * 2)!;
        checkPath.lineTo(currentPoint.dx, currentPoint.dy);
      }

      canvas.drawPath(checkPath, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}