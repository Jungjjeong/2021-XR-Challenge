package com.google.ar.sceneform.samples.gltf;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;






// 3D Viewer list

public class List3dActivity extends AppCompatActivity {

    ArrayList<SampleData> dataList;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_list3d);

        this.InitializeData();

        ListView listView = (ListView) findViewById(R.id.listview);
        final ListAdapter listadapter = new ListAdapter(this, dataList);

        listView.setAdapter(listadapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView parent, View view, int position, long l) {

                int key = listadapter.getItem(position).getKey();
//                String newUri = "http://www.hanssem.store/" + key;
                String newUri = "http://210.94.185.38:8080/3D/test.html";
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(newUri));

                startActivity(intent);

//                Toast.makeText(getApplicationContext(), listadapter.getItem(position).getFullName(), Toast.LENGTH_LONG).show();
            }
        });
    }

    public void InitializeData(){
        dataList = new ArrayList<SampleData>();

        dataList.add(new SampleData(R.drawable.i668317, 0, "하이 엠마 천연가죽 3인용 소파", 211));
        dataList.add(new SampleData(R.drawable.i681947, 1, "하이 모먼트 헤드무빙 천연가죽 소파 3인용", 210));
        dataList.add(new SampleData(R.drawable.i737687, 2, "하이 브리오 이태리 천연가죽 3.5인용 소파", 240));
        dataList.add(new SampleData(R.drawable.i746526, 3, "프라임 노블 천연면피가죽 전동 리클라이너 소파 3인용", 192));
        dataList.add(new SampleData(R.drawable.i746540, 4, "프라임 리츠 천연면피가죽 전동 리클라이너 소파 4인용", 263));
        dataList.add(new SampleData(R.drawable.i772973, 5, "클로즈 침대 SS 슈퍼싱글 코튼그레이", 116));
        dataList.add(new SampleData(R.drawable.i777039, 6, "밀로 패브릭소파 3인용", 200));
        dataList.add(new SampleData(R.drawable.i786840, 7, "모아 모듈형 패브릭소파 3인용", 252));
        dataList.add(new SampleData(R.drawable.i786841, 8, "모아 모듈형 패브릭소파 3인 카우치", 252));
        dataList.add(new SampleData(R.drawable.i796416, 9, "엠마 테일러 천연면피가죽 3인용 소파", 185));
        dataList.add(new SampleData(R.drawable.i799215, 10, "엠마 컴포트 천연면피가죽 3인용 소파", 200));

    }
}