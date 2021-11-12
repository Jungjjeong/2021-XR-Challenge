package com.google.ar.sceneform.samples.gltf;


import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.google.ar.core.Anchor;
import com.google.ar.core.HitResult;
import com.google.ar.core.Pose;
import com.google.ar.sceneform.AnchorNode;
import com.google.ar.sceneform.FrameTime;
import com.google.ar.sceneform.Node;
import com.google.ar.sceneform.math.Quaternion;
import com.google.ar.sceneform.math.Vector3;
import com.google.ar.sceneform.rendering.Color;
import com.google.ar.sceneform.rendering.MaterialFactory;
import com.google.ar.sceneform.rendering.ModelRenderable;
import com.google.ar.sceneform.rendering.ShapeFactory;
import com.google.ar.sceneform.ux.ArFragment;
import com.google.ar.sceneform.ux.TransformableNode;

import java.text.DecimalFormat;
import java.util.Objects;


// 거리 측정 페이지

public class DistanceActivity extends AppCompatActivity implements com.google.ar.sceneform.Scene.OnUpdateListener {


    private static final double MIN_OPENGL_VERSION = 3.0;
    private static final String TAG = DistanceActivity.class.getSimpleName();

    private ArFragment arFragment;
    private AnchorNode currentAnchorNode,currentAnchorNode_1;
    private TextView tvDistance;
    ModelRenderable cubeRenderable;
    private Anchor currentAnchor = null,currentAnchor_1=null;
    private static int countForAnchorsProduced=0;
    private static final DecimalFormat df = new DecimalFormat("0.00");


    Anchor anchor ;
    AnchorNode anchorNode ;
    private String selectedMode="meters"; // 초기 선택된 단위는 meters


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (!checkIsSupportedDeviceOrFinish(this)) { // requirements check
            Toast.makeText(getApplicationContext(), "Device not supported", Toast.LENGTH_LONG).show();
        }

        setContentView(R.layout.activity_distance); // activity_distance.xml

        arFragment = (ArFragment) getSupportFragmentManager().findFragmentById(R.id.ux_fragment);
        tvDistance = findViewById(R.id.tvDistance);


        // model init
        initModel();

        Intent intent = getIntent();
        int key = (int) intent.getSerializableExtra("key");
        int size = (int) intent.getSerializableExtra("size");


        // Gltf Activity로 이동
        Button button_back = findViewById(R.id.button_back);
        button_back.setOnClickListener(v -> {
            Intent pageIntent = new Intent(DistanceActivity.this, GltfActivity.class);
            pageIntent.putExtra("key", key);
            pageIntent.putExtra("size", size);
            startActivity(pageIntent);
            finish();
        });

        arFragment.setOnTapArPlaneListener((hitResult, plane, motionEvent) -> {
            if (cubeRenderable == null)
                return;

            // Anchor Count
            countForAnchorsProduced++;
            if(countForAnchorsProduced==1)
            {
                Anchor anchor = hitResult.createAnchor();
                AnchorNode anchorNode = new AnchorNode(anchor);
                anchorNode.setParent(arFragment.getArSceneView().getScene());

                currentAnchor = anchor;
                currentAnchorNode = anchorNode;

                TransformableNode node = new TransformableNode(arFragment.getTransformationSystem());
                node.setRenderable(cubeRenderable);
                node.setParent(anchorNode);
                arFragment.getArSceneView().getScene().addOnUpdateListener(this);
                arFragment.getArSceneView().getScene().addChild(anchorNode);
                node.select();

            }
            if(countForAnchorsProduced==2)
            {
                // Creating Anchor.
                Anchor anchor_1 = hitResult.createAnchor();
                AnchorNode anchorNode_1 = new AnchorNode(anchor_1);
                anchorNode_1.setParent(arFragment.getArSceneView().getScene());

                currentAnchor_1=anchor_1;
                currentAnchorNode_1=anchorNode_1;


                TransformableNode node_1 = new TransformableNode(arFragment.getTransformationSystem());
                node_1.setRenderable(cubeRenderable);
                node_1.setParent(anchorNode_1);
                arFragment.getArSceneView().getScene().addOnUpdateListener(this);
                arFragment.getArSceneView().getScene().addChild(anchorNode_1);
                node_1.select();
                addLineBetweenHits(hitResult, motionEvent);
            }
            // Anchor 2개 초과일 시 초기화 후 재시작
            if(countForAnchorsProduced>2)
            {
                //set to default text
                tvDistance.setText("터치해서 시작");
                countForAnchorsProduced=0;
                clearAnchor();
            }
        });

        // 단위 선택 가능한 DropDown list 생성
        Spinner dropdown = findViewById(R.id.dropdown_list);
        // 단위 할당 ( meters, cms, inches )
        String[] items = new String[]{"meters","cms","inches"};
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, items);

        dropdown.setAdapter(adapter);
        dropdown.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view,
                                       int position, long id)
            {
                Log.v("item", (String) parent.getItemAtPosition(position));
                switch (position)
                {
                    case 1:
                        selectedMode="cms";
                        break;
                    case 2:
                        selectedMode="inches";
                        break;
                    default:
                        selectedMode="meters";
                        break;
                }
            }
            // default -> meters
            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // TODO Auto-generated method stub
                selectedMode="meters";
            }
        });
        dropdown.setSelection(0);

    }


    // Model (cubeRenderable) init
    private void initModel() {
        MaterialFactory
                .makeTransparentWithColor(this, new Color(android.graphics.Color.WHITE))
                .thenAccept(
                        material -> {
                            cubeRenderable = ShapeFactory.makeSphere(0.015f, Vector3.zero(), material);
                            cubeRenderable.setShadowCaster(false);
                            cubeRenderable.setShadowReceiver(false);
                        });
    }


    // Clear Anchor
    private void clearAnchor() {
        currentAnchor = null;
        currentAnchor_1=null;

        if (currentAnchorNode != null && currentAnchorNode_1!=null)
        {
            arFragment.getArSceneView().getScene().removeChild(currentAnchorNode);
            assert currentAnchorNode.getAnchor() != null;
            currentAnchorNode.getAnchor().detach();
            currentAnchorNode.setParent(null);
            currentAnchorNode = null;

            arFragment.getArSceneView().getScene().removeChild(currentAnchorNode_1);
            assert currentAnchorNode_1.getAnchor() != null;
            currentAnchorNode_1.getAnchor().detach();
            currentAnchorNode_1.setParent(null);
            currentAnchorNode_1 = null;

            arFragment.getArSceneView().getScene().removeChild(anchorNode);
            assert anchorNode.getAnchor() != null;
            anchorNode.getAnchor().detach();
            anchorNode.setParent(null);
            anchorNode = null;
        }

    }


    // Frametime마다 호출되는 콜백 func
    @Override
    public void onUpdate(FrameTime frameTime) {
        Log.d("API123", "onUpdateframe... current anchor node " + (currentAnchorNode == null));

        if (currentAnchorNode != null && currentAnchorNode_1!=null) {
            Pose objectPose = currentAnchor.getPose();
            Pose objectPose_1= currentAnchor_1.getPose();


            // 거리 측정 -> 지속적으로 업데이트
            float dx_1 = objectPose.tx() - objectPose_1.tx();
            float dy_1 = objectPose.ty() - objectPose_1.ty();
            float dz_1 = objectPose.tz() - objectPose_1.tz();
            float distanceMeasured=(float) Math.sqrt(dx_1 * dx_1 + dy_1 * dy_1 + dz_1 * dz_1);
            switch (selectedMode) {
                case "meters":
                    break;
                case "cms":
                    distanceMeasured = distanceMeasured * 100;
                    break;
                case "inches":
                    //standard conversion from meters to inches
                    distanceMeasured = distanceMeasured * 39.3701f;
                    break;
            }
            String distanceMeters = df.format(distanceMeasured);

            // 측정된 거리 textView Rendering
            tvDistance.setText("측정 길이: " + distanceMeters + " " + selectedMode);

        }
    }



    // Two Hits -> 거리 측정되어 Rendering + 두 cubeRenderable 사이 Line 생성
    // Line 생성 func
    private void addLineBetweenHits(HitResult hitResult, MotionEvent motionEvent) {

        int val = motionEvent.getActionMasked();
        float axisVal = motionEvent.getAxisValue(MotionEvent.AXIS_X, motionEvent.getPointerId(motionEvent.getPointerCount() - 1));
        Log.e("Values:", String.valueOf(val) + axisVal);
        anchor = hitResult.createAnchor();
        anchorNode = new AnchorNode(anchor);


        if (currentAnchorNode != null)
        {
            anchorNode.setParent(arFragment.getArSceneView().getScene());
            Vector3 point1, point2;
            point1 = currentAnchorNode.getWorldPosition();
            point2 = anchorNode.getWorldPosition();

            final Vector3 difference = Vector3.subtract(point1, point2);
            final Vector3 directionFromTopToBottom = difference.normalized();
            final Quaternion rotationFromAToB =
                    Quaternion.lookRotation(directionFromTopToBottom, Vector3.up());
            MaterialFactory.makeOpaqueWithColor(getApplicationContext(), new Color(android.graphics.Color.WHITE))
                    .thenAccept(
                            material -> {
                                ModelRenderable model = ShapeFactory.makeCube(
                                        new Vector3(.01f, .01f, difference.length()),
                                        Vector3.zero(), material);

                                model.setShadowCaster(false);
                                model.setShadowReceiver(false);

                                Node node = new Node();
                                node.setParent(anchorNode);
                                node.setRenderable(model);
                                node.setWorldPosition(Vector3.add(point1, point2).scaled(.5f));
                                node.setWorldRotation(rotationFromAToB);
                            }
                    );
        }
    }




    // Version Check
    public boolean checkIsSupportedDeviceOrFinish(final Activity activity) {

        String openGlVersionString;
        openGlVersionString = ((ActivityManager) Objects.requireNonNull(activity.getSystemService(Context.ACTIVITY_SERVICE)))
                .getDeviceConfigurationInfo()
                .getGlEsVersion();
        if (Double.parseDouble(openGlVersionString) < MIN_OPENGL_VERSION)
        {
            Log.e(TAG, "Sceneform requires OpenGL ES 3.0 later");
            Toast.makeText(activity, "Sceneform requires OpenGL ES 3.0 or later", Toast.LENGTH_LONG)
                    .show();
            activity.finish();
            return false;
        }
        return true;
    }
}
