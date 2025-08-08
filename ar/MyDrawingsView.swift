//
//  MyDrawingsView.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-14.
//

import Foundation
import MapKit
import SwiftUI

struct MyDrawingsView: View {
    @ObservedObject var viewModel: DrawingViewModel
    @Environment(\.dismiss) var dismiss
    @State var showDeleteWarning = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.allDrawings) { drawing in
                    NavigationLink {
                        DrawingLocationView(drawing: drawing)
                    } label: {
                        DrawingCellView(drawing: drawing)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.delete(drawing)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                
                ForEach(viewModel.allTextNodes) { textNode in
                    NavigationLink {
                        TextNodeLocationView(textNode: textNode)
                    } label: {
                        TextNodeCellView(textNode: textNode)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteText(textNode)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("My Drawings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete All") {
                        showDeleteWarning.toggle()
                    }
                }
            }
            .alert("Are you sure?", isPresented: $showDeleteWarning) {
                Button("Cancel") {}
                Button("Delete All") {
                    viewModel.wipeAll()
                    dismiss()
                }
            }
        }
    }
}

struct DrawingCellView: View {
    let drawing: Drawing
    @State private var postion: MapCameraPosition

    init(drawing: Drawing) {
        self.drawing = drawing
        self.postion = MapCameraPosition.region(
            MKCoordinateRegion(
                center: drawing.coordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        )
    }
    var body: some View {
        HStack(spacing: 16) {
            Text(drawing.title)
                .font(.headline)
                
            Spacer()
            
            VStack {
                Text("\(drawing.coordinates.latitude)")
                Text("\(drawing.coordinates.longitude)")
            }
            .font(.callout)
        }
        .foregroundStyle(Color.primary)
    }
}

struct DrawingLocationView: View {
    let drawing: Drawing
    @State private var postion: MapCameraPosition

    init(drawing: Drawing) {
        self.drawing = drawing
        self.postion = MapCameraPosition.region(
            MKCoordinateRegion(
                center: drawing.coordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        )
    }
    
    var body: some View {
        ZStack {
            Map(position: $postion) {
                Marker(coordinate: drawing.coordinates) {
                    
                }
            }
            .navigationTitle(drawing.title)
            .ignoresSafeArea()
        }
    }
}

struct TextNodeCellView: View {
    let textNode: TextNode
    @State private var postion: MapCameraPosition

    init(textNode: TextNode) {
        self.textNode = textNode
        self.postion = MapCameraPosition.region(
            MKCoordinateRegion(
                center: textNode.coordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        )
    }
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(textNode.title)
                    .font(.headline)
                Text(textNode.text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
                
            Spacer()
            
            VStack {
                Text("\(textNode.coordinates.latitude)")
                Text("\(textNode.coordinates.longitude)")
            }
            .font(.callout)
        }
        .foregroundStyle(Color.primary)
    }
}

struct TextNodeLocationView: View {
    let textNode: TextNode
    @State private var postion: MapCameraPosition

    init(textNode: TextNode) {
        self.textNode = textNode
        self.postion = MapCameraPosition.region(
            MKCoordinateRegion(
                center: textNode.coordinates,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        )
    }
    
    var body: some View {
        ZStack {
            Map(position: $postion) {
                Marker(coordinate: textNode.coordinates) {
                    
                }
            }
            .navigationTitle(textNode.title)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        DrawingCellView(drawing: .init(title: "2", coordinates: .init(latitude: 43.657372, longitude:  -79.464082), points: []))
    }
}
