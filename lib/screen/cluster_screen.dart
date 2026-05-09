import 'package:flutter/material.dart';
import 'package:flutter_cluster/components/glass_card.dart';
import 'package:flutter_cluster/components/gear_selector.dart';
import 'package:flutter_cluster/components/traffic_lights.dart';
import 'package:flutter_cluster/components/turn_signal_indicators.dart';
import 'package:flutter_cluster/components/navigation_message.dart';
import 'package:flutter_cluster/constants/app_color.dart';
import 'package:provider/provider.dart';
import '../provider/cluster_provider.dart';
import '../proto/vehicle_frame.pb.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class ClusterScreen extends StatelessWidget {
  const ClusterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<VehicleFrameNotifier>();
    final frame = notifier.latest;

    if (notifier.error != null) {
      return _ErrorView(message: notifier.error!);
    }
    if (frame == null) {
      return const _LoadingView();
    }
    return ClusterView(frame: frame);
  }
}

// ── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00E5FF),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'CONNECTING',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 11,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, color: Color(0xFFFF3D57), size: 40),
            const SizedBox(height: 16),
            const Text(
              'CONNECTION LOST',
              style: TextStyle(
                color: Color(0xFFFF3D57),
                fontSize: 11,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0x66FFFFFF),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main cluster view ─────────────────────────────────────────────────────────

class ClusterView extends StatelessWidget {
  final VehicleFrame frame;
  const ClusterView({required this.frame});

  @override
  Widget build(BuildContext context) {
    final speed = frame.velocity.speedKmh;
    final gear = gearSelect(frame.gear.value);  //return string 
    final controlMode = frame.controlMode.value;  //return string 
    final battery = frame.batteryPct;
    final isMrm = frame.mrm.isActive;
    final MrmBehavior = frame.mrm.behavior.value;
    final turnSignal = frame.turnSignal.value; // 0=none 1=left 2=right
    final maxSpeed = frame.speedLimitMps;
    final targetSpeed = frame.targetSpeedMps;
    final etaDistance = frame.eta.remainingDistanceM;
    final etaTime = frame.eta.remainingTimeS;
    final motionState = frame.motionState.value;
    final hazard = frame.hazardOn;
    final acc = frame.kinematics.accelMps2;
    final yawRate = frame.kinematics.yawRate;
    final countCars = frame.adas.vehicleCount;
    final countObstacles = frame.adas.obstacleCount;
    final countPedstrain = frame.adas.pedestrianCount;
    final tlRed = frame.adas.trafficLightRed;
    final tlGreen = frame.adas.trafficLightGreen;
    final tlYellow = frame.adas.trafficLightYellow;
  




    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Stack(
          children: [
            //blue light
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/blue_light.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            //road
            Positioned(
              top: 300,
              left: 0,
              right: 0,

              child: Image.asset('assets/images/road.png', fit: BoxFit.cover),
            ),

            //top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopBar(gear: gear, hazard: hazard),
            ),

            //left , right indicators
            Positioned(
              top: 60,
              left: 350,
              right: 350,
              child: TurnSignalIndicator(turnSignal: turnSignal),
            ),
            
            //navigation message
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: NavMessage(
                  turnDirection: turnSignal,
                  distanceM: 500,
                ),
              ),
            ),

            //speed
            Positioned(top: 140, left: 120, child: build_display(speed, 'KM/H' , 0)),

            //energy
            Positioned(top: 140, right: 120, child: build_display(3.4, 'KM/H' , 1)),

            //middle car
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,

              child: Center(
                child: Image.asset(
                  'assets/images/car_middle.png',
                  width: 160,
                  height: 130,
                ),
              ),
            ),

            //truck
            Positioned(
              bottom: 240,
              right: 260,

              child: Image.asset(
                'assets/images/truck.png',
                width: 200,
                height: 160,
              ),
            ),

            //left car
            Positioned(
              bottom: 240,
              left: 300,

              child: Image.asset(
                'assets/images/left_car.png',
                width: 154,
                height: 90,
              ),
            ),

            //left card information
            Positioned(
              left: 24,
              bottom: 100,
              child: LeftCardInfo(
                acc: acc,
                max_speed: maxSpeed,
                target_speed: targetSpeed,
                yaw_rate: yawRate,
              ),
            ),

            //right card information
            Positioned(
              right: 24,
              bottom: 100,
              child: RightCarfIngo(
                eta_distance: etaDistance,
                eta_time: etaTime,
               is_mrm: isMrm,
               mrm_behavior: MrmBehavior,
                odometer: 25.00,
              ),
            ),

            //bottom bar
            Positioned(
              bottom: 16,
              left: 24,
              right: 24,
              child: Center(
                child: BottomBar(
                  battery: 90,
                  car_count: countCars,
                  control_mode: controlMode,
                  motion_state: motionState,
                  obstacle_count: countObstacles,
                  pedstrain_count: countPedstrain,
                  TL_green: tlGreen,
                  TL_red: tlRed,
                  TL_yellow: tlYellow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String gearSelect(int v) {
    switch (v) {
      case 1:
        return 'P';
      case 2:
        return 'R';
      case 3:
        return 'N';
      case 4:
        return 'D';
      default:
        return '';
    }
  }
}

// top bar
class TopBar extends StatelessWidget {
  final String gear;
  final bool hazard;
  const TopBar({super.key, required this.gear, required this.hazard});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Stack(
          children: [
            GlassCard(
              width: double.infinity,
              height: 40,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  children: [
                    //time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        //time value
                        Text(
                          '12:15',
                          style: TextStyle(
                            color: AppColor.primary_text_dark,
                            fontFamily: 'Nasalization',
                            fontSize: 16,
                          ),
                        ),

                        SizedBox(width: 4),
                        //unit
                        Text(
                          'AM',
                          style: TextStyle(
                            color: AppColor.primary_text_dark,
                            fontFamily: 'inter',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    Spacer(),

                    if (hazard)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'HAZARD',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(width: 120),

                    //temerature
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        //temerature vale
                        Text(
                          '27',
                          style: TextStyle(
                            color: AppColor.primary_text_dark,
                            fontFamily: 'Nasalization',
                            fontSize: 16,
                          ),
                        ),

                        SizedBox(width: 4),
                        //unit
                        Text(
                          'C',
                          style: TextStyle(
                            color: AppColor.primary_text_dark,
                            fontFamily: 'Nasalization',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: GlassCard(
                width: 400,
                height: 70,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                  bottomRight: Radius.circular(100),
                ),

                child: Center(child: GearSelector(activeLetter: gear)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//bottom bar
class BottomBar extends StatelessWidget {
  final double battery;
  final int control_mode; //(AUTO = 2 /MANUAL = 1 /NONE = 0)
  final int
  motion_state; //(STOPPED = 1 /MOVING = 2 /DECELERATING = 3 /NONE = 0)
  final int car_count;
  final int obstacle_count;
  final int pedstrain_count;
  final bool TL_red;
  final bool TL_green;
  final bool TL_yellow;

  const BottomBar({
    super.key,
    required this.battery,
    required this.car_count,
    required this.control_mode,
    required this.motion_state,
    required this.obstacle_count,
    required this.pedstrain_count,
    required this.TL_green,
    required this.TL_red,
    required this.TL_yellow,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      height: 60,
      width: 1400,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            //left row
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  build_battery(),
                  const SizedBox(width: 48),
                  build_control_mode(control_mode),
                  const SizedBox(width: 48),
                  build_motion_state(motion_state),
                ],
              ),
            ),

            //traffic lights
            Center(child: buildTrafficLight(TL_red, TL_yellow, TL_green)),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //car count
                  build_icon('assets/icons/car.svg', 25, 20, car_count),
                  SizedBox(width: 30),
                  //obstacle count
                  build_icon(
                    'assets/icons/obstacle.svg',
                    25,
                    20,
                    obstacle_count,
                  ),
                  SizedBox(width: 30),
                  //pedstrain count
                  build_icon(
                    'assets/icons/pedstrain.svg',
                    25,
                    20,
                    pedstrain_count,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row build_icon(String icon_path, double icon_w, double icon_h, int count) {
    return Row(
      children: [
        //car icon
        SvgPicture.asset(
          '$icon_path',
          width: icon_w,
          height: icon_h,
          colorFilter: ColorFilter.mode(
            AppColor.icon_dark_white,
            BlendMode.srcIn,
          ),
        ),

        //vertical line
        Container(
          height: 20,
          child: VerticalDivider(color: AppColor.action_color, thickness: 1),
        ),

        //car count
        Text(
          '$count',
          style: TextStyle(
            color: AppColor.action_color,
            fontFamily: 'Nasalization',
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Row build_battery() {
    return Row(
      children: [
        //battery icon
        SvgPicture.asset(
          'assets/icons/battery.svg',
          width: 50,
          height: 30,
          colorFilter: ColorFilter.mode(
            AppColor.icon_dark_white,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: 4),
        //battery level
        Text(
          '${battery.toStringAsFixed(0)}%',
          style: TextStyle(
            color: AppColor.icon_dark_white,
            fontFamily: 'Nasalization',
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Text build_control_mode(int v) {
    String mode = '';
    switch (v) {
      case 1:
        mode = 'MANUAL';
        break;
      case 2:
        mode = 'AUTO';
        break;
      default:
        mode = '';
    }
    return Text(
      '$mode',
      style: TextStyle(
        color: AppColor.action_color,
        fontFamily: 'inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Row build_motion_state(int v) {
    String motion = '';
    switch (v) {
      case 1:
        motion = 'STOPPED';
        break;
      case 2:
        motion = 'MOVING';
        break;
      case 3:
        motion = 'DECELERATING';
        break;
      default:
        motion = '';
    }
    return Row(
      children: [
        if (v == 1 || v == 2 || v == 3)
          SvgPicture.asset(
            'assets/icons/blue_filled_circle.svg',
            width: 20,
            height: 20,
          ),

        SizedBox(width: 8),

        Text(
          '$motion',
          style: TextStyle(
            color: AppColor.action_color,
            fontFamily: 'inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

//right card information

class RightCarfIngo extends StatelessWidget {
  final double eta_distance;
  final double eta_time;
  final double odometer;
  final bool is_mrm;
  final int mrm_behavior;
  const RightCarfIngo({
    super.key,
    required this.eta_distance,
    required this.eta_time,
    required this.is_mrm,
    required this.mrm_behavior,
    required this.odometer,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 200,
      height: 350,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: build_info('Estimated Distance', eta_distance, 'm' , 0),
            ),

            build_light_line(),

            Expanded(child: build_info('Estimated Time', eta_time, 's' , 0)),

            build_light_line(),

            Expanded(child: build_info('Odometer', odometer, 'm' , 0)),

            build_light_line(),

           Expanded(child: build_info_mrm('MRM', is_mrm ,mrm_behavior)),
         

          ],
        ),
      ),
    );
  }
}



//build mrm info 
Column build_info_mrm(String label , bool is_active , int v){
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [ 
       Text(
        '$label',
        style: TextStyle(
          color: AppColor.secondary_text_dark,
          fontSize: 14,
          fontFamily: 'inter',
          fontWeight: FontWeight.w200,
        ),
      ),
      

     
           Row(
             children: [
               Text(
                is_active?'${mrm_behavior(v)}':'Inactive',
                style: TextStyle(
                 color: AppColor.action_color,
                 fontFamily: 'inter',
                 fontWeight: FontWeight.normal,
                 fontSize: 18
                ),
               ),
             ],
           ),
    ],
  );
}


String mrm_behavior(int v){
  switch(v){
    case 1:
    return 'Pull Over';
    case 2: 
    return 'Emergency';
    default :
    return '';
  }
  
}

// left card information

class LeftCardInfo extends StatelessWidget {
  final double acc;
  final double target_speed;
  final double max_speed;
  final double yaw_rate;

  const LeftCardInfo({
    super.key,
    required this.acc,
    required this.max_speed,
    required this.target_speed,
    required this.yaw_rate,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 200,
      height: 350,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: build_info('Acceleration', acc, 'KM/H' , 1)),

            build_light_line(),

            Expanded(child: build_info('Target Speed', target_speed, 'm/s' , 0)),

            build_light_line(),

            Expanded(child: build_info('Max Speed', max_speed, 'm/s' , 0)),

            build_light_line(),

            Expanded(child: build_info('Yaw Rate', yaw_rate, 'Rad/s' , 1)),
          ],
        ),
      ),
    );
  }
}

Image build_light_line() {
  return Image.asset(
    'assets/images/light_line.png',
    width: 180,
    height: 20,
    fit: BoxFit.fitWidth,
  );
}

Column build_info(String label, dynamic value, String unit , int n) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label',
        style: TextStyle(
          color: AppColor.secondary_text_dark,
          fontSize: 14,
          fontFamily: 'inter',
          fontWeight: FontWeight.w200,
        ),
      ),

      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${value.toStringAsFixed(n)}',
            style: TextStyle(
              color: AppColor.action_color,
              fontFamily: 'Nasalization',
              fontSize: 20,
            ),
          ),

          SizedBox(width: 4),

          Text(
            '$unit',
            style: TextStyle(
              color: AppColor.secondary_text_dark,
              fontFamily: 'inter',
              fontSize: 12,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    ],
  );
}

//speed  and energy

Row build_display(double val, String unit , int n) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      //value
      Text(
        '${val.toStringAsFixed(n)}',
        style: TextStyle(
          color: AppColor.primary_text_dark,
          fontFamily: 'Nasalization',
          fontSize: 70,
        ),
      ),

      //unit
      Text(
        '$unit',
        style: TextStyle(
          color: AppColor.secondary_text_dark,
          fontFamily: 'inter',
          fontSize: 15,
          fontWeight: FontWeight.w200,
        ),
      ),
    ],
  );
}
