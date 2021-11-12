package com.google.ar.sceneform.samples.gltf;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Point;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.support.design.widget.NavigationView;
import android.support.v4.view.GravityCompat;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.AppCompatActivity;
import android.util.ArraySet;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;

import com.google.android.filament.gltfio.Animator;
import com.google.android.filament.gltfio.FilamentAsset;
import com.google.ar.core.Anchor;
import com.google.ar.core.Frame;
import com.google.ar.core.HitResult;
import com.google.ar.core.Plane;
import com.google.ar.core.Trackable;
import com.google.ar.sceneform.AnchorNode;
import com.google.ar.sceneform.Node;
import com.google.ar.sceneform.rendering.Color;
import com.google.ar.sceneform.rendering.Material;
import com.google.ar.sceneform.rendering.ModelRenderable;
import com.google.ar.sceneform.rendering.Renderable;
import com.google.ar.sceneform.rendering.ViewRenderable;
import com.google.ar.sceneform.ux.ArFragment;
import com.google.ar.sceneform.ux.TransformableNode;

import java.lang.ref.WeakReference;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import android.os.Handler;

import static java.util.concurrent.TimeUnit.SECONDS;




// 가구 AR 배치 페이지

public class GltfActivity extends AppCompatActivity {
    private static final String TAG = GltfActivity.class.getSimpleName(); // log 띄우기 위해
    private static final double MIN_OPENGL_VERSION = 3.0;


    private ArFragment arFragment; // ARCORE 기본 구성 사용
    private Renderable renderable; // sceneform rendering basic class -> rendering 가능한 3D model 생성
    private AnchorNode currentAnchorNode;
//    // + gltf file road, rendering -> Modelrenderable의 개체 생성을 처리
//    private ViewRenderable viewRenderable;
//    public boolean bool = false;





    private static class AnimationInstance { // animation을 만들기 위해 사용되는 데이터들
        Animator animator;
        Long startTime;
        float duration;
        int index;

        AnimationInstance(Animator animator, int index, Long startTime) {
            this.animator = animator;
            this.startTime = startTime;
            this.duration = animator.getAnimationDuration(index);
            this.index = index;
        }

        public AnimationInstance(com.google.android.filament.gltfio.Animator animator, int index, long startTime) {
        }
    }

    private final Set<AnimationInstance> animators = new ArraySet<>(); // animationInstance 저장하기 위해 ArraySet 생성

    private final List<Color> colors =
            Arrays.asList(
                    new Color(0, 0, 0, 1),
                    new Color(1, 0, 0, 1),
                    new Color(0, 1, 0, 1),
                    new Color(0, 0, 1, 1),
                    new Color(1, 1, 0, 1),
                    new Color(0, 1, 1, 1),
                    new Color(1, 0, 1, 1),
                    new Color(1, 1, 1, 1));
    private int nextColor = 0; //

    private String fileUri;

    private ProgressDialog progressDialog;
    final String[] Glburi = new String[22];

    @Override
    @SuppressWarnings({"AndroidApiChecker", "FutureReturnValueIgnored"})
    // CompletableFuture requires api level 24
    // FutureReturnValueIgnored is not valid
    protected void onCreate(Bundle savedInstanceState) {
        WeakReference<GltfActivity> weakActivity = new WeakReference<>(this); // Weakreference -> MemoryLeak X
        // 다른 Class에서 activity를 포함한 객체를 참조하거나, 별도의 스레드에서 view, activity를 참조하고 있는 경우, 해당 참조를 주어 메모리 누수를 방지한다.
        // sceneform의 ModelAnimator은 약한 참조만을 이용한다. 일반 soft나 strongreference를 사용하기 위해서는 해당 객체를 Node에 추가해야 한다.

        super.onCreate(savedInstanceState);


        setContentView(R.layout.activity_ux);

        progressDialog = new ProgressDialog(this);
        progressDialog.getWindow().setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));

        if (!checkIsSupportedDeviceOrFinish(this)) {
            return;
        } // 지원하는 OpenGL 버전(3.0)이 적합한지, android sdk 버전이 맞는지 확인

        Glburi[0] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/668317.glb";
        Glburi[1] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/668318.glb";
        Glburi[2] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/681946.glb";
        Glburi[3] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/681947.glb";
        Glburi[4] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/737686.glb";
        Glburi[5] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/737687.glb";
        Glburi[6] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/746525.glb";
        Glburi[7] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/746526.glb";
        Glburi[8] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/746540.glb";
        Glburi[9] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/746541.glb";
        Glburi[10] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/772973.glb";
        Glburi[11] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/777039.glb";
        Glburi[12] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/777040.glb";
        Glburi[13] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/786840.glb";
        Glburi[14] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/786841.glb";
        Glburi[15] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/786842.glb";
        Glburi[16] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/787819.glb";
        Glburi[17] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/787823.glb";
        Glburi[18] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/796379.glb";
        Glburi[19] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/796379.glb";
        Glburi[20] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/796379.glb";
        Glburi[21] = "https://raw.githubusercontent.com/justbeaver97/2021-Summer-ValueUpProject/master/test_asset/799220.glb";


        // -----
        Intent intent = getIntent();
        int key = (int) intent.getSerializableExtra("key");
        fileUri = Glburi[key];

        int size = (int) intent.getSerializableExtra("size"); // get items -> key, size(length)



        // 거리 측정 페이지 -> DistanceActivity 로 이동
        Button button_distance = findViewById(R.id.button_distance);
        button_distance.setOnClickListener(v -> {
            Toast.makeText(getApplicationContext(), "거리 측정페이지입니다.", Toast.LENGTH_LONG).show();
            Intent pageIntent = new Intent(GltfActivity.this, DistanceActivity.class); // 거리측정페이지 : DistanceActivity
            pageIntent.putExtra("size", size); // length 전달
            pageIntent.putExtra("key", key);
            startActivity(pageIntent);
            finish();
        });

        DrawerLayout drawerLayout = findViewById(R.id.drawerLayout);
        Button button_list = findViewById(R.id.button_list);
        button_list.setOnClickListener(v -> drawerLayout.openDrawer(GravityCompat.START));


        // ProgressDialog
        progressDialog.setCanceledOnTouchOutside(false);
        progressDialog.setCancelable(false);

        final Handler handler = new Handler();
        final Runnable runnable = () -> {
            if(progressDialog.isShowing()){
                progressDialog.dismiss();
            }
        };

        NavigationView navigationView = findViewById(R.id.nav);
        // List에서 상품 선택시
        navigationView.setNavigationItemSelectedListener(menuItem -> {

            menuItem.setChecked(true);
            drawerLayout.closeDrawers();

            progressDialog.show();

            int id = menuItem.getItemId();
            String title = menuItem.getTitle().toString();

            if(id==R.id.menu_668317){
                fileUri = Glburi[0];
                buildModel(weakActivity,getBaseContext(), fileUri);
            }else if(id == R.id.menu_681947){
                fileUri = Glburi[3];
                buildModel(weakActivity,getBaseContext(), fileUri);
            }else if(id == R.id.menu_737687){
                fileUri = Glburi[5];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_746526){
                fileUri = Glburi[7];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_746540){
                fileUri = Glburi[8];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_772973){
                fileUri = Glburi[10];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_777039){
                fileUri = Glburi[11];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_786840){
                fileUri = Glburi[13];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_786841){
                fileUri = Glburi[14];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_796416){
                fileUri = Glburi[19];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }else if(id == R.id.menu_799215){
                fileUri = Glburi[20];
                buildModel(weakActivity,getBaseContext(), fileUri );
            }

            Toast.makeText(getApplicationContext(), "현재 상품 : " + title, Toast.LENGTH_LONG).show();

            handler.postDelayed(runnable, 5000);

            return true;
        });



//        String newUri = "http://image.hanssem.com/hsimg/gds3d/dk/" + key + ".glb";

        arFragment = (ArFragment) getSupportFragmentManager().findFragmentById(R.id.ux_fragment); // ux_fragment -> fragment manager 불러옴 -> ARFragment

        progressDialog.show();
        buildModel(weakActivity, this, fileUri );

        progressDialog.setOnDismissListener(dialogInterface -> handler.removeCallbacks(runnable));

        handler.postDelayed(runnable, 3000); // 임의의 시간동안 ProgressDialog

        Button button_refresh = findViewById(R.id.button_refresh);
        ImageView imageView = findViewById(R.id.squareImage);



        // Anchor 초기화 func
        button_refresh.setOnClickListener(v -> {
                    if (arFragment.getArSceneView().getScene().getChildren() != null) {
                        System.out.println("refresh");

                        if (currentAnchorNode != null)
                        {
                            arFragment.getArSceneView().getScene().removeChild(currentAnchorNode);
                            assert currentAnchorNode.getAnchor() != null;
                            currentAnchorNode.getAnchor().detach();
                            currentAnchorNode.setParent(null);
                            currentAnchorNode = null;
                        }

                        arFragment.onStart();
                    }
                   imageView.setVisibility(View.VISIBLE);
                }
        );


//        arFragment.setOnTapArPlaneListener( // Plane의 white dot tap하면 function 실행 -> hitresult(x,y), plane, motionEvent -> Anchor 생성 가능
//                (HitResult hitResult, Plane plane, MotionEvent motionEvent) -> {
//                    if (renderable == null) {
//                        return;
//                    }
//
//                    // Create the Anchor.
//                    Anchor anchor = hitResult.createAnchor(); // create anchor
//                    AnchorNode anchorNode = new AnchorNode(anchor); // Object가 배치되는 영역인 Node를 Anchor 할당 생성 -> AnchorNode
//                    anchorNode.setParent(arFragment.getArSceneView().getScene()); // (getScene : 장면 반환 / getArSceneView : 장면 랜더링(arsceneview) 반환) -> parentNode로 set
//
//                    // Create the transformable model and add it to the anchor.
//                    TransformableNode model = new TransformableNode(arFragment.getTransformationSystem()); // TransformableNode -> 선택, 변환, 회전, 크기 조정 가능한 Node
//                    model.setRenderable(renderable); // set rendering model
//                    model.getScaleController().setMaxScale(0.015f);
//                    model.getScaleController().setMinScale(0.005f); // set Scale
//                    model.setParent(anchorNode); // Anchor node 위에 model set -> 부모 설정
//
//                    model.select();
//
//                    // Filament -> android, iOS 등 WebGL을 위한 실시간 Rendering engine
//                    FilamentAsset filamentAsset = model.getRenderableInstance().getFilamentAsset(); // filamentAsset = filament에서 사용할 3D 모델(.glb file) 정의
//                    if (filamentAsset.getAnimator().getAnimationCount() > 0) {
//                        animators.add(new AnimationInstance(filamentAsset.getAnimator(), 0, System.nanoTime())); // Array set animators -> add Instance
//                    }
//
//                    Color color = colors.get(nextColor); // basic color setting
//                    nextColor++;
//                    for (int i = 0; i < renderable.getSubmeshCount(); ++i) {
//                        Material material = renderable.getMaterial(i);
//                        material.setFloat4("baseColorFactor", color);
//                    }
//                });
//



        arFragment
                .getArSceneView()
                .getScene()
                .addOnUpdateListener( // Scene이 update되기 직전 frame 당 한번 호출될 콜백함수
                        frameTime -> {
                            Long time = System.nanoTime(); // nanotime 만큼
//
//                            addToScene();
//                            createViewRenderable(weakActivity);
//                            System.out.println(bool);
//                            if (bool) {
//                                imageView.setVisibility(View.INVISIBLE);
//                            }

//                            System.out.println(arFragment.getArSceneView().getScene().getCamera().getWorldRotation().w);

                            for (AnimationInstance animator : animators) {
                                animator.animator.applyAnimation(
                                        animator.index,
                                        (float) ((time - animator.startTime) / (double) SECONDS.toNanos(1))
                                                % animator.duration);
                                animator.animator.updateBoneMatrices();
                            } // set animation
                        }
        );


        // 하단 중앙 버튼 누르면, 화면 중앙에서 hitTest 수행 -> 가구 배치 func
        Button addButton = findViewById(R.id.button_add);
        addButton.setOnClickListener(v -> {
            try{
                if (renderable == null) {
                    return;
                }
                HitResult hitResult = null;
                Point pt = new Point(arFragment.getArSceneView().getWidth() / 2, arFragment.getArSceneView().getHeight() /2);
                List<HitResult> hits;
                Frame frame = arFragment.getArSceneView().getArFrame();
                if (frame != null) {
                    hits = frame.hitTest(pt.x, pt.y);
                    for (HitResult hit : hits) {
                        Trackable trackable = hit.getTrackable();
                        if (trackable instanceof Plane && ((Plane) trackable).isPoseInPolygon(hit.getHitPose())) {
                            hitResult = hit;
                            break;
                        }
                    }
                }
                // Create the Anchor.
                assert hitResult != null;
                Anchor anchor = hitResult.createAnchor(); // create anchor
                AnchorNode anchorNode = new AnchorNode(anchor); // Object가 배치되는 영역인 Node를 Anchor 할당 생성 -> AnchorNode
                anchorNode.setParent(arFragment.getArSceneView().getScene()); // (getScene : 장면 반환 / getArSceneView : 장면 랜더링(arsceneview) 반환) -> parentNode로 set

                currentAnchorNode = anchorNode;

                // Create the transformable model and add it to the anchor.
                TransformableNode model = new TransformableNode(arFragment.getTransformationSystem()); // TransformableNode -> 선택, 변환, 회전, 크기 조정 가능한 Node
                model.setRenderable(renderable); // set rendering model
                model.getScaleController().setMaxScale(0.015f);
                model.getScaleController().setMinScale(0.005f); // set Scale
                model.setParent(anchorNode); // Anchor node 위에 model set -> 부모 설정

                model.select();

                // Filament -> android, iOS 등 WebGL을 위한 실시간 Rendering engine
                assert model.getRenderableInstance() != null;
                FilamentAsset filamentAsset = model.getRenderableInstance().getFilamentAsset(); // filamentAsset = filament에서 사용할 3D 모델(.glb file) 정의
                assert filamentAsset != null;
                if (filamentAsset.getAnimator().getAnimationCount() > 0) {
                    animators.add(new AnimationInstance(filamentAsset.getAnimator(), 0, System.nanoTime())); // Array set animators -> add Instance
                }

                Color color = colors.get(nextColor); // basic color setting
                nextColor++;
                for (int i = 0; i < renderable.getSubmeshCount(); ++i) {
                    Material material = renderable.getMaterial(i);
                    material.setFloat4("baseColorFactor", color);
                }
                Toast myToast = Toast.makeText(this.getApplicationContext(), "가구가 배치되었습니다.", Toast.LENGTH_SHORT);
                myToast.show();
                imageView.setVisibility(View.INVISIBLE);
            }catch (Exception e){
                // 화면 중앙에 평면이 인식되어 있지 않으면 예외처리
                Toast myToast = Toast.makeText(this.getApplicationContext(), "평면이 인식된 곳에서 버튼을 눌러주세요.", Toast.LENGTH_SHORT);
                myToast.show();
            }
        });
    }




    // 가구 Loading
    public void buildModel(WeakReference<GltfActivity> weakActivity,Context context, String uri) {

                ModelRenderable.builder() // Sceneform rendering engine -> gltf 파일 로드 및 개체 생성
                        .setSource(context, Uri.parse(uri)) // our .glb model
                        .setIsFilamentGltf(true) // gltf load
                        .build()
                        .thenAccept(
                                modelRenderable -> {
                                    GltfActivity activity = weakActivity.get(); // 참조
                                    if (activity != null) {
                                        activity.renderable = modelRenderable; // modelRenderable(our .glb file) -> renderable
                                    }
                                })
                        .exceptionally( // exception
                                throwable -> {
                                    Toast toast =
                                            Toast.makeText(this, "인테리어 파일을 불러올 수 없습니다.", Toast.LENGTH_LONG);
                                    toast.setGravity(Gravity.CENTER, 0, 0);
                                    toast.show();
                                    return null;
                                });
    }



    // Version Check
    public static boolean checkIsSupportedDeviceOrFinish(final Activity activity) { // version check function
        String openGlVersionString =
                ((ActivityManager) activity.getSystemService(Context.ACTIVITY_SERVICE))
                        .getDeviceConfigurationInfo()
                        .getGlEsVersion();
        if (Double.parseDouble(openGlVersionString) < MIN_OPENGL_VERSION) {
            Log.e(TAG, "Sceneform requires OpenGL ES 3.0 later");
            Toast.makeText(activity, "Sceneform requires OpenGL ES 3.0 or later", Toast.LENGTH_LONG)
                    .show();
            activity.finish();
            return false;
        }
        return true;
    }
}
