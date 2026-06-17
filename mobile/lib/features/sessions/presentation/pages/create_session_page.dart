import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../di/injection.dart';
import '../../data/datasources/sessions_remote_data_source.dart';
import '../bloc/sessions_bloc.dart';
import '../bloc/sessions_event.dart';
import '../bloc/sessions_state.dart';

class CreateSessionPage extends StatefulWidget {
  const CreateSessionPage({Key? key}) : super(key: key);

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  // Restaurant
  List<RestaurantOption> _restaurants = [];
  RestaurantOption? _selectedRestaurant;
  bool _loadingRestaurants = true;
  String? _restaurantError;

  // People
  int _maxAttendees = 4;

  // Date & Time
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 19, minute: 0);

  // Range
  int _rangeKm = 10;

  // Bill Split
  String _splitType = 'EQUAL'; // EQUAL = 50/50, HOST_PAYS = 100/0, PERCENTAGE = custom

  // Transport / Pickup
  String _hostTransportMode = 'MEET_THERE';
  bool _hasRideAvailable = false;
  int _availableRideSeats = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final ds = getIt<SessionsRemoteDataSource>();
      final list = await ds.fetchRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = list;
          _loadingRestaurants = false;
          _restaurantError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restaurantError = e.toString();
          _loadingRestaurants = false;
        });
      }
    }
  }

  DateTime get _fullScheduledDateTime => DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SessionsBloc>(),
      child: BlocListener<SessionsBloc, SessionsState>(
        listener: (context, state) {
          if (state is SessionCreateSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Eating plan created! 🎉',
                      style: GoogleFonts.outfit(),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          if (state is SessionsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.outfit()),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Make a Plan',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                    ),
                    child: const Center(
                      child: Icon(Icons.restaurant_menu,
                          color: Colors.white24, size: 80),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        icon: Icons.restaurant,
                        title: 'Choose a Restaurant',
                        child: _buildRestaurantPicker(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        icon: Icons.people,
                        title: 'Number of People',
                        child: _buildPeoplePicker(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        icon: Icons.calendar_today,
                        title: 'Date & Time',
                        child: _buildDateTimePicker(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        icon: Icons.explore,
                        title: 'Range / Visibility',
                        child: _buildRangePicker(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        icon: Icons.receipt_long,
                        title: 'Bill Split',
                        child: _buildBillSplitPicker(),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        icon: Icons.directions_car,
                        title: 'Transport / Pickup',
                        child: _buildTransportPicker(),
                      ),
                      const SizedBox(height: 32),
                      _buildCreateButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRestaurantPicker() {
    if (_loadingRestaurants) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_restaurants.isEmpty) {
      return Text(
        _restaurantError != null
            ? 'No restaurants available.\nError: $_restaurantError'
            : 'No restaurants available. Make sure the backend is running.',
        style: GoogleFonts.outfit(color: AppColors.textSecondary),
      );
    }
    return DropdownButtonFormField<RestaurantOption>(
      value: _selectedRestaurant,
      hint: Text('Select a restaurant', style: GoogleFonts.outfit()),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _restaurants.map((r) {
        return DropdownMenuItem(
          value: r,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r.name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                r.address,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedRestaurant = val),
    );
  }

  Widget _buildPeoplePicker() {
    return Row(
      children: [
        _circleButton(
          Icons.remove,
          () => setState(() {
            if (_maxAttendees > 2) _maxAttendees--;
          }),
        ),
        Expanded(
          child: Center(
            child: Column(
              children: [
                Text(
                  '$_maxAttendees',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'people (including you)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        _circleButton(
          Icons.add,
          () => setState(() {
            if (_maxAttendees < 12) _maxAttendees++;
          }),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_scheduledDate);
    final timeStr = _scheduledTime.format(context);

    return Row(
      children: [
        Expanded(
          child: _pickerTile(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: dateStr,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pickerTile(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: timeStr,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Widget _buildRangePicker() {
    return Row(
      children: [
        Expanded(
          child: _rangeOption(
            label: 'People Near Me',
            sublabel: '10 km radius',
            icon: Icons.near_me,
            selected: _rangeKm == 10,
            onTap: () => setState(() => _rangeKm = 10),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _rangeOption(
            label: 'Explore',
            sublabel: '30 km radius',
            icon: Icons.public,
            selected: _rangeKm == 30,
            onTap: () => setState(() => _rangeKm = 30),
          ),
        ),
      ],
    );
  }

  Widget _rangeOption({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              sublabel,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: selected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSplitPicker() {
    return Column(
      children: [
        _splitOption(
          value: 'EQUAL',
          title: '50/50 — Split Equally',
          subtitle: 'Everyone pays their equal share',
          icon: Icons.balance,
        ),
        const SizedBox(height: 8),
        _splitOption(
          value: 'HOST_PAYS',
          title: '100/0 — Host Treats',
          subtitle: 'You\'re covering the whole bill',
          icon: Icons.volunteer_activism,
        ),
        const SizedBox(height: 8),
        _splitOption(
          value: 'PERCENTAGE',
          title: 'Custom Split',
          subtitle: 'Set individual percentages',
          icon: Icons.percent,
        ),
      ],
    );
  }

  Widget _splitOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _splitType == value;
    return GestureDetector(
      onTap: () => setState(() => _splitType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportPicker() {
    return Column(
      children: [
        _transportOption(
          value: 'MEET_THERE',
          rideAvail: false,
          title: 'Arrive on My Own',
          subtitle: 'Everyone makes their own way',
          icon: Icons.directions_walk,
        ),
        const SizedBox(height: 8),
        _transportOption(
          value: 'RIDE_TOGETHER',
          rideAvail: true,
          title: 'I\'ll Offer Pickup',
          subtitle: 'You can take others along',
          icon: Icons.directions_car,
        ),
        const SizedBox(height: 8),
        _transportOption(
          value: 'MEET_THERE',
          rideAvail: false,
          title: 'Need a Ride',
          subtitle: 'You\'re looking for a pickup',
          icon: Icons.hail,
        ),
      ],
    );
  }

  Widget _transportOption({
    required String value,
    required bool rideAvail,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _hostTransportMode == value &&
        _hasRideAvailable == rideAvail;
    return GestureDetector(
      onTap: () => setState(() {
        _hostTransportMode = value;
        _hasRideAvailable = rideAvail;
        if (rideAvail) _availableRideSeats = _maxAttendees - 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Builder(builder: (context) {
      return BlocBuilder<SessionsBloc, SessionsState>(
        builder: (ctx, state) {
          final loading = state is SessionsLoading;
          return GestureDetector(
            onTap: loading ? null : () => _submit(ctx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                gradient: loading
                    ? const LinearGradient(
                        colors: [Colors.grey, Colors.grey])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: loading
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Create Eating Plan',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      );
    });
  }

  void _submit(BuildContext ctx) {
    if (_selectedRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a restaurant.',
              style: GoogleFonts.outfit()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final dt = _fullScheduledDateTime;
    if (dt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please pick a future date and time.',
              style: GoogleFonts.outfit()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    ctx.read<SessionsBloc>().add(CreateSessionRequested(
          restaurantId: _selectedRestaurant!.id,
          restaurantName: _selectedRestaurant!.name,
          restaurantLocation: _selectedRestaurant!.address,
          scheduledAt: dt,
          maxAttendees: _maxAttendees,
          foodCategory: _selectedRestaurant!.cuisineTags.isNotEmpty
              ? _selectedRestaurant!.cuisineTags.first.toString()
              : 'Pakistani',
          splitType: _splitType,
          hasRideAvailable: _hasRideAvailable,
          availableRideSeats: _availableRideSeats,
          hostTransportMode: _hostTransportMode,
          rangeKm: _rangeKm,
        ));
  }
}
