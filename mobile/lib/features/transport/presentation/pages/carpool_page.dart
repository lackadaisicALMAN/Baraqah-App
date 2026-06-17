import 'package:baraqah_mobile/core/widgets/app_button.dart';
import 'package:baraqah_mobile/core/widgets/error_card.dart';
import 'package:baraqah_mobile/core/widgets/loading_indicator.dart';
import 'package:baraqah_mobile/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/carpool.dart';
import '../bloc/transport_bloc.dart';
import '../bloc/transport_event.dart';
import '../bloc/transport_state.dart';

class CarpoolPage extends StatelessWidget {
  static const String routeName = '/carpools';
  const CarpoolPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransportBloc>()..add(FetchCarpoolsRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Carpool Seats')),
        body: BlocConsumer<TransportBloc, TransportState>(
          listener: (context, state) {
            if (state is SeatPickSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seat picked successfully')));
            }
            if (state is TransportFailure) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is TransportLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is TransportFailure) {
              return Center(child: ErrorCard(message: state.message));
            }
            if (state is TransportLoadSuccess) {
              return _CarpoolList(carpools: state.carpools);
            }
            return const Center(child: Text('No carpools available.'));
          },
        ),
      ),
    );
  }
}

class _CarpoolList extends StatelessWidget {
  final List<Carpool> carpools;
  const _CarpoolList({Key? key, required this.carpools}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: carpools.length,
      itemBuilder: (context, index) {
        final carpool = carpools[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(carpool.driverName),
            subtitle:
                Text('Pickup: ${carpool.pickup} • Dropoff: ${carpool.dropoff}'),
            trailing: Text('${carpool.availableSeats} seats'),
            onTap: () => _pickSeat(context, carpool),
          ),
        );
      },
    );
  }

  void _pickSeat(BuildContext context, Carpool carpool) {
    final seatNumber = 1;
    context
        .read<TransportBloc>()
        .add(PickSeatRequested(carpoolId: carpool.id, seatNumber: seatNumber));
  }
}
