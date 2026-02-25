import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:remixicon/remixicon.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_sticky_headers/table_sticky_headers.dart';

class TransportIconMap {
  final String modeName;
  final Map<String, List<IconData>> icons;

  TransportIconMap({required this.modeName, required this.icons});
}

class IconComparisonPage extends StatefulWidget {
  const IconComparisonPage({super.key});

  @override
  State<IconComparisonPage> createState() => _IconComparisonPageState();
}

class _IconComparisonPageState extends State<IconComparisonPage> {
  final List<String> packageNames = [
    'Material (Default)',
    'MDI',
    'Cupertino',
    'FontAwesome',
    'Ionicons',
    'Feather',
    'Remix',
    'Eva',
    'LineAwesome',
  ];

  late final List<TransportIconMap> transportModes;

  @override
  void initState() {
    super.initState();
    transportModes = _buildTransportModes();
  }

  List<TransportIconMap> _buildTransportModes() {
    return [
      TransportIconMap(
        modeName: 'Bus',
        icons: {
          'Material (Default)': [Icons.directions_bus, Icons.directions_bus_filled, Icons.bus_alert],
          'MDI': [MdiIcons.bus, MdiIcons.busAlert, MdiIcons.busStop],
          'Cupertino': [CupertinoIcons.bus],
          'FontAwesome': [FontAwesomeIcons.bus, FontAwesomeIcons.busSimple],
          'Ionicons': [Ionicons.bus, Ionicons.bus_outline, Ionicons.bus_sharp],
          'Feather': [], // No bus icon in feather?
          'Remix': [Remix.bus_fill, Remix.bus_line, Remix.bus_2_fill],
          'Eva': [], // No bus icon in eva?
          'LineAwesome': [LineAwesomeIcons.bus_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Train / Railway',
        icons: {
          'Material (Default)': [Icons.train, Icons.directions_railway, Icons.directions_railway_filled],
          'MDI': [MdiIcons.train, MdiIcons.trainCar, MdiIcons.railroadLight],
          'Cupertino': [CupertinoIcons.train_style_one, CupertinoIcons.train_style_two],
          'FontAwesome': [FontAwesomeIcons.train, FontAwesomeIcons.trainSubway, FontAwesomeIcons.trainTram],
          'Ionicons': [Ionicons.train, Ionicons.train_outline, Ionicons.train_sharp],
          'Feather': [],
          'Remix': [Remix.train_fill, Remix.train_line],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.train_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Subway / Metro',
        icons: {
          'Material (Default)': [Icons.subway, Icons.directions_subway, Icons.directions_subway_filled],
          'MDI': [MdiIcons.subway, MdiIcons.subwayVariant],
          'Cupertino': [],
          'FontAwesome': [FontAwesomeIcons.trainSubway],
          'Ionicons': [Ionicons.subway, Ionicons.subway_outline, Ionicons.subway_sharp],
          'Feather': [],
          'Remix': [Remix.subway_fill, Remix.subway_line],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.subway_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Tram / Light Rail',
        icons: {
          'Material (Default)': [Icons.tram, Icons.directions_transit, Icons.directions_transit_filled],
          'MDI': [MdiIcons.tram, MdiIcons.trainCarPassenger],
          'Cupertino': [],
          'FontAwesome': [FontAwesomeIcons.trainTram],
          'Ionicons': [],
          'Feather': [],
          'Remix': [],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.tram_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Bicycle / Cycling',
        icons: {
          'Material (Default)': [Icons.pedal_bike, Icons.directions_bike],
          'MDI': [MdiIcons.bicycle, MdiIcons.bike],
          'Cupertino': [], // Check if Cupertino has bike
          'FontAwesome': [FontAwesomeIcons.bicycle],
          'Ionicons': [Ionicons.bicycle, Ionicons.bicycle_outline, Ionicons.bicycle_sharp],
          'Feather': [],
          'Remix': [Remix.bike_fill, Remix.bike_line],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.bicycle_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Walking / Pedestrian',
        icons: {
          'Material (Default)': [Icons.directions_walk, Icons.hiking],
          'MDI': [MdiIcons.walk, MdiIcons.hiking],
          'Cupertino': [],
          'FontAwesome': [FontAwesomeIcons.personWalking],
          'Ionicons': [Ionicons.walk, Ionicons.walk_outline, Ionicons.walk_sharp],
          'Feather': [FeatherIcons.user, FeatherIcons.mapPin],
          'Remix': [Remix.walk_fill, Remix.walk_line],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.walking_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Car / Driving',
        icons: {
          'Material (Default)': [Icons.directions_car, Icons.directions_car_filled, Icons.drive_eta],
          'MDI': [MdiIcons.car, MdiIcons.carHatchback, MdiIcons.carSide],
          'Cupertino': [CupertinoIcons.car, CupertinoIcons.car_fill],
          'FontAwesome': [FontAwesomeIcons.car, FontAwesomeIcons.carSide],
          'Ionicons': [Ionicons.car, Ionicons.car_outline, Ionicons.car_sharp],
          'Feather': [FeatherIcons.truck],
          'Remix': [Remix.car_fill, Remix.car_line],
          'Eva': [EvaIcons.car, EvaIcons.carOutline],
          'LineAwesome': [LineAwesomeIcons.car_solid, LineAwesomeIcons.car_alt_solid, LineAwesomeIcons.car_side_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Taxi / Rideshare',
        icons: {
          'Material (Default)': [Icons.local_taxi, Icons.hail],
          'MDI': [MdiIcons.taxi, MdiIcons.carEstate],
          'Cupertino': [],
          'FontAwesome': [FontAwesomeIcons.taxi],
          'Ionicons': [], // Ionicons usually doesn't have taxi specific
          'Feather': [],
          'Remix': [Remix.taxi_fill, Remix.taxi_line],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.taxi_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Ferry / Boat',
        icons: {
          'Material (Default)': [Icons.directions_boat, Icons.directions_boat_filled, Icons.directions_ferry],
          'MDI': [MdiIcons.ferry, MdiIcons.sailBoat],
          'Cupertino': [],
          'FontAwesome': [FontAwesomeIcons.ferry, FontAwesomeIcons.ship],
          'Ionicons': [Ionicons.boat, Ionicons.boat_outline, Ionicons.boat_sharp],
          'Feather': [FeatherIcons.anchor],
          'Remix': [Remix.ship_fill, Remix.ship_line, Remix.sailboat_fill],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.ship_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Airplane / Flight',
        icons: {
          'Material (Default)': [Icons.flight, Icons.flight_takeoff, Icons.flight_land],
          'MDI': [MdiIcons.airplane, MdiIcons.airplaneTakeoff, MdiIcons.airplaneLanding],
          'Cupertino': [CupertinoIcons.airplane],
          'FontAwesome': [FontAwesomeIcons.plane, FontAwesomeIcons.planeDeparture, FontAwesomeIcons.planeArrival],
          'Ionicons': [Ionicons.airplane, Ionicons.airplane_outline, Ionicons.airplane_sharp],
          'Feather': [FeatherIcons.send],
          'Remix': [Remix.plane_fill, Remix.plane_line],
          'Eva': [EvaIcons.globe, EvaIcons.globe2, EvaIcons.globe2Outline], // Eva doesn't have plane?
          'LineAwesome': [LineAwesomeIcons.plane_solid],
        },
      ),
      TransportIconMap(
        modeName: 'Scooter',
        icons: {
          'Material (Default)': [Icons.electric_scooter, Icons.moped],
          'MDI': [MdiIcons.scooter, MdiIcons.scooterElectric],
          'Cupertino': [],
          'FontAwesome': [],
          'Ionicons': [],
          'Feather': [],
          'Remix': [Remix.motorbike_fill, Remix.motorbike_line],
          'Eva': [],
          'LineAwesome': [LineAwesomeIcons.motorcycle_solid],
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Comparison'),
      ),
      body: StickyHeadersTable(
        columnsLength: packageNames.length,
        rowsLength: transportModes.length,
        columnsTitleBuilder: (i) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            packageNames[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        rowsTitleBuilder: (i) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            transportModes[i].modeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        contentCellBuilder: (i, j) {
          final packageName = packageNames[i];
          final mode = transportModes[j];
          final icons = mode.icons[packageName] ?? [];

          if (icons.isEmpty) {
            return const Center(child: Text('-', style: TextStyle(color: Colors.grey)));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: icons.map((icon) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(icon, size: 32.0),
              )).toList(),
            ),
          );
        },
        legendCell: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Mode \\ Pkg', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        cellDimensions: const CellDimensions.uniform(width: 150, height: 60),
      ),
    );
  }
}
