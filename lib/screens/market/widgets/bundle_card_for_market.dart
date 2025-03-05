import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:boxify/app_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:boxify/screens/market/api/purchase_api.dart';

class BundleCardForMarketScreen extends StatefulWidget {
  BundleCardForMarketScreen({
    super.key,
    required this.bundle,
  });

  final Bundle bundle;

  @override
  State<BundleCardForMarketScreen> createState() =>
      _BundleCardForMarketScreenState();
}

class _BundleCardForMarketScreenState extends State<BundleCardForMarketScreen> {
  final audioPlayer = ap.AudioPlayer();
  bool _isPlaying = false;

  _play(String url) async {
    logger.i('play:$_isPlaying');
    if (url == '') {
      return;
    }
    _isPlaying
        ? await audioPlayer.pause()
        : await audioPlayer.play(ap.UrlSource(url));
    url = url.replaceFirst('dl=0', 'raw=1');
    setState(() {
      _isPlaying = !_isPlaying;
    });

    logger.i('play2:$_isPlaying');
  }

  _stop() async {
    await audioPlayer.stop();
    try {
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      logger.e(e);
    }
  }

  @override
  void dispose() {
    _stop();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> buy(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final userBloc = context.read<UserBloc>();
    // final artistBloc = context.read<ArtistBloc>();
    final marketBloc = context.read<MarketBloc>();

    logger.i(
      'MARKET.horizontal_list_view_item.buy hash ${identityHashCode(userBloc)}: market.status=${marketBloc.state.status}',
    );
    await Purchases.logIn(authBloc.state.user!.uid);

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    var revenueCatId = widget.bundle.revenueCatId!;

    isIOS ? revenueCatId += '_ios' : revenueCatId = revenueCatId;
    logger.i('revenueCatId:$revenueCatId');
    final List<StoreProduct> products;

    products = await PurchaseApi.fetchProductsByIds([revenueCatId]);
    logger.i(products);

    if (products.isNotEmpty) {
      final bool isSuccess;
      isSuccess = await PurchaseApi.purchaseProduct(products.first);
      logger.i('isSuccess: $isSuccess');

      if (isSuccess) {
        final email = authBloc.state.user!.email!;
        marketBloc.add(
            PurchaseBundle(id: widget.bundle.id, user: userBloc.state.user));
        // final message =
        //     "You now have access to all the tracks in '${widget.bundle.title!}'. Please check $email for a download link (check spam, if necessary). Email assistant@riverscuomo.com with any problems.";
        // showMySnack(context, message: message);

        showPurchaseDialog(context, widget.bundle.title!, email);
      } else {
        showMySnack(context, message: 'purchaseCancelled'.translate());
      }
    } else {
      final snackbar = buildSnackbar(
        "I was unable to find a product with the id: '$revenueCatId'",
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  void showPurchaseDialog(
      BuildContext context, String bundleTitle, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Purchase Successful'),
          content: Text(
            "You now have access to all the tracks in '$bundleTitle'. Please check $email for a download link (check spam, if necessary). Email assistant@riverscuomo.com with any problems.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Core.appColor.primary)),
            ),
          ],
        );
      },
    );
  }

  _openBundlePreview(Bundle bundle) {
    _play(bundle.preview!);
    final songList = bundle.songList?.split(',');
    final userState = context.read<UserBloc>().state;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Column(
          children: [
            if (bundle.image != null)
              SizedBox(
                height: 200,
                child: CachedNetworkImage(
                  imageUrl: bundle.image!.replaceAll('dl=0', 'raw=1'),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )
            else
              Text(bundle.image.toString()),
            Text(bundle.title!),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // DEMO COUNT
              Text(
                '${widget.bundle.count!} demos from ${widget.bundle.years!}',
              ),
              const SizedBox(height: 15),

              /// DESCRIPTION
              Text(bundle.description ?? ''),
              const SizedBox(height: 20),

              /// SONG LIST
              SizedBox(
                height: 220,
                width: 220,
                child: ListView.builder(
                  itemCount: songList!.length,
                  itemBuilder: (context, i) {
                    return Text(
                      songList[i].trim(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              )
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'close'.translate(),
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () {
              info('openBundlePreview:close');
              _stop();
              Navigator.of(dialogContext).pop(); // Corrected this line
            },
          ),
          if (bundle.isOwned == false)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                info('openBundlePreview:buy');
                audioPlayer.stop();
                if (UserHelper.isLoggedInOrReroute(userState, context,
                    'actionBuyBundles'.translate(), Icons.music_note_rounded)) {
                  await buy(context)
                      .then((value) => GoRouter.of(context).pop());
                }
              },
              child: Text(
                'buy'.translate(),
              ),
            )
          else
            Container(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openBundlePreview(widget.bundle),
      child: Container(
        color: Core.appColor.hoverColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundedCornersImage(
              imageUrl: widget.bundle.image,
              height: 190,
              width: 190,
            ),
            // bundle NAME
            TextOrMarquee(
              text: widget.bundle.title!,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 11.0,
                  ),
            ),

            Text(
              widget.bundle.years!,
              style: TextStyle(
                fontSize: 11.0,
                color: Colors.grey[300],
              ),
            ),
            if (widget.bundle.isOwned == true)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'youAlreadyOwnThis'.translate(),
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                    fontSize: 13.0,
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    final userState = context.read<UserBloc>().state;
                    if (UserHelper.isLoggedInOrReroute(
                        userState,
                        context,
                        'actionBuyBundles'.translate(),
                        Icons.music_note_rounded)) {
                      await buy(context);
                    }
                  },
                  child: Text(
                    // '\$${widget.bundle.priceString!}',
                    'buy'.translate(),
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
              ),
            if (widget.bundle.isNew == true)
              Align(
                alignment: Alignment.center,
                child: Text(
                  'new'.translate(),
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Container(),
          ],
        ),
      ),
    );
  }
}
