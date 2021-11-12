package com.google.ar.sceneform.samples.gltf;


import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;


// Main Page

public class MainActivity extends AppCompatActivity {
    Button button_list;
    @Override
    protected void onCreate(Bundle savedInstanceState) { // basic app start logic
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        button_list = findViewById(R.id.button_list);
    }
    // AR Viewer
    public void onClickARButton(View v) {
        Intent intent = new Intent(getApplicationContext(),ListARActivity.class); // AR LIST
        startActivity(intent);
    }

    // 3D Viewer
    public void onClickViewerButton(View v) {
        Intent intent = new Intent(getApplicationContext(),List3dActivity.class); // 3D LIST
//        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("http://www.hanssem.store/"));
        startActivity(intent);
    }
}

