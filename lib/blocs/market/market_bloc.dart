import 'dart:async';
import 'package:boxify/app_core.dart';
import 'package:boxify/services/bundles_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'market_event.dart';
part 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final UserRepository _userRepository;
  final BundleRepository _bundleRepository;
  late final StreamSubscription authBlocSubscription;
  final CacheHelper _cacheHelper;
  final UserHelper _userHelper;

  MarketBloc({
    required AuthBloc authBloc,
    required UserRepository userRepository,
    required TrackRepository trackRepository,
    required PlaylistRepository playlistRepository,
    required MetaDataRepository metaDataRepository,
    required StorageRepository storageRepository,
    required BundleRepository bundleRepository,
  })  : _userRepository = userRepository,
        _bundleRepository = BundleRepository(),
        _cacheHelper = CacheHelper(),
        _userHelper = UserHelper(),
        super(MarketState.initial()) {
    on<InitialMarketState>(_onInitialMarketState);
    on<LoadMarket>(_onLoadMarket);
    on<PurchaseBundle>(_onPurchaseBundle);
  }

  Future<void> _onInitialMarketState(
    InitialMarketState event,
    Emitter<MarketState> emit,
  ) async {
    emit(MarketState.initial());
  }

  Future<void> _onLoadMarket(
      LoadMarket event, Emitter<MarketState> emit) async {
    final start = DateTime.now();

    logger.i('_onLoadMarket: ${event.user.id}');

    emit(state.copyWith(status: MarketStatus.loading));

    // check for cached bundles
    final cachedBundles = await _cacheHelper.getBundles(event.serverTimestamp);
    // final cachedBundles = null;

    List counts;
    List<Bundle> allBundles = [];

    if (cachedBundles != null) {
      counts = _userHelper.calculateCounts(event.user, cachedBundles);
      allBundles = cachedBundles;
    } else {
      allBundles = await _bundleRepository.loadBundles(event.user.id);

      await _cacheHelper.saveBundles(allBundles);

      counts = _userHelper.calculateCounts(event.user, allBundles);
    }

    // Initialize the bundles manager
    BundleManager().updateBundles(allBundles);

    final unpurchasedBundles = allBundles
        .where((bundle) => !event.user.bundleIds.contains(bundle.id))
        .toList();

    emit(state.copyWith(
      status: MarketStatus.loaded,
      bundleCount: counts[0],
      trackCount: counts[1],
      userBundleCount: counts[2],
      userTrackCount: counts[3],
      allBundles: allBundles,
      unpurchasedBundles: unpurchasedBundles,
    ));
    // final end = DateTime.now();
    // logger.f('Time to load market: ${end.difference(start)}');
    logRunTime(start, 'load market');
  }

  void _onPurchaseBundle(PurchaseBundle event, Emitter<MarketState> emit) {
    logger.i('_purchaseBundle: ${event.id}');

    try {
      emit(state.copyWith(status: MarketStatus.bundlePurchasing));

      // Update the user bundleIds in firestore
      _userRepository.addRemoveUserBundles(
        bundleId: event.id!,
        user: event.user,
        switchOff: false,
      );

      // Create a copy of the event's user with the updated bundleIds
      final updatedUser = event.user.copyWith(
        bundleIds: event.user.bundleIds..add(event.id!),
      );

      // Create a new list for allBundles with the updated isOwned flag
      final updatedAllBundles = state.allBundles.map((Bundle bundle) {
        if (updatedUser.bundleIds.contains(bundle.id)) {
          return bundle.copyWith(isOwned: true);
        }
        return bundle;
      }).toList();

      // Email the bundle to the user
      final purchasedBundle =
          state.allBundles.firstWhere((bundle) => bundle.id == event.id);
      _bundleRepository.emailBundleAndSavePurchaseToFirestore(
          event.user, purchasedBundle);

      // Remove the purchased bundle from the available market bundles
      final unpurchasedBundles = state.allBundles
          .where((bundle) => !updatedUser.bundleIds.contains(bundle.id))
          .toList();

      // todo: update the user
      // todo: update the tracks

      emit(
        state.copyWith(
          unpurchasedBundles: unpurchasedBundles,
          purchasedBundle: purchasedBundle,
          allBundles: updatedAllBundles,
          status: MarketStatus.bundlePurchased,
        ),
      );
    } catch (err) {
      logger.e('MarketBloc err=$err');
      emit(
        state.copyWith(
          status: MarketStatus.error,
          failure: const Failure(
            message:
                'I was unable to update your user record with the bundle purchase. Email me at rivers@riverscuomo.com',
          ),
        ),
      );
    }
  }
}
