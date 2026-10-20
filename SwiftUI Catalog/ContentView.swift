//
//  ContentView.swift
//  SwiftUI Catalog
//
//  Created by Koichi Yamamoto on 2026/10/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Sheet") {
                    SheetCatalogView()
                }
            }
            .navigationTitle("SwiftUI Catalog")
        }
    }
}

#Preview {
    ContentView()
}
