import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;


class ArrCoreScreen extends StatefulWidget {
  const ArrCoreScreen({Key key,}) : super(key: key);

  @override
  State<ArrCoreScreen> createState() => _ArrCoreScreenState();
}

class _ArrCoreScreenState extends State<ArrCoreScreen> {

  ArCoreController arCoreController;
  ArCoreNode node;
  @override
  void dispose() {
    super.dispose();
    arCoreController.dispose();
  }
   _onArCoreViewCreated(ArCoreController controller){
     arCoreController = controller;
     _addKhungLong(arCoreController);

     //_addSphere(arCoreController);
    //  arCoreController.onPlaneDetected = _handleOnPlaneDected;
   }
   /*_handleOnPlaneDected(ArCorePlane plane){
     if(node != null){
       arCoreController.removeNode(nodeName: node.name);
     }
     _addKhungLong(arCoreController, plane);
   }*/

  
   _addKhungLong(ArCoreController controller){
    final node = ArCoreReferenceNode(
       name: 'Khủng Long',
       object3DFileName: 'Toon.sfb',
       scale: vector.Vector3(0.5,0.5,0.5),
       position: vector.Vector3(-0,-1,-1),
       rotation: vector.Vector4(0,180,0,0)
     );
     controller.addArCoreNode(node);
   } 

   _addSphere(ArCoreController controller, ArCorePlane plane){
     final material = ArCoreMaterial(color: Colors.red);
     final sphere = ArCoreSphere(materials: [material], radius: 0.2);
     node = ArCoreNode(
       name: 'Sphere',
       shape: sphere,
       position: plane.centerPose.translation,
       rotation: plane.centerPose.rotation
     );
     controller.addArCoreNode(node);
   }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: ArCoreView(
        onArCoreViewCreated: _onArCoreViewCreated,
        enableUpdateListener: true,
      ),
    );
  }
}
