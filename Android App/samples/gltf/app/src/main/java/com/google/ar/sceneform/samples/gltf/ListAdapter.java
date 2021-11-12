package com.google.ar.sceneform.samples.gltf;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.ar.sceneform.samples.gltf.R;
import com.google.ar.sceneform.samples.gltf.SampleData;

import java.util.ArrayList;




// List Adapter

public class ListAdapter extends BaseAdapter { // ListAdapter for using Listview

    Context mContext = null;
    LayoutInflater mLayoutInflater = null; // 다른 클래스에서 xml가져오기
    ArrayList<SampleData> sample;

    public ListAdapter(Context context, ArrayList<SampleData> data){
        mContext = context;
        sample = data;
        mLayoutInflater = LayoutInflater.from(mContext); // Layout xml 파일을 for_listView 객체로 인스턴스화
    }

    @Override
    public int getCount() {
        return sample.size();
    } // get list item count

    @Override
    public long getItemId(int position) { // get current item position
        return position;
    }

    @Override
    public SampleData getItem(int position){
        return sample.get(position);
    } // get item

    @Override
    public View getView(int position, View converView, ViewGroup parent) {
        View view = mLayoutInflater.inflate(R.layout.for_listview, null);

        ImageView imageView = (ImageView) view.findViewById(R.id.image);
        TextView fullName = (TextView) view.findViewById(R.id.fullName);

        imageView.setImageResource(sample.get(position).getImage());
        fullName.setText(sample.get(position).getFullName());

        return view;
    }
}
