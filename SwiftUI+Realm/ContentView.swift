//
//  ContentView.swift
//  SwiftUI+Realm
//
//  Created by Takuya Yokoyama on 2020/02/03.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI
import RealmSwift

struct ContentView: View {
    @EnvironmentObject private var store: Store
    
    var body: some View {
        List {
            ForEach(store.itemEntities) { (itemEntity: ItemEntity) in
                if itemEntity.isInvalidated {
                    EmptyView()
                } else {
                    Text(itemEntity.name)
                }
            }
        }.onAppear {
            ItemEntity.setUp()
        }
    }
}

import Combine
class Store: ObservableObject {
    var objectWillChange: ObservableObjectPublisher = .init()
    private(set) var itemEntities: Results<ItemEntity> = ItemEntity.all()
    private var notificationTokens: [NotificationToken] = []
    
    init() {
        notificationTokens.append(itemEntities.observe { _ in
            self.objectWillChange.send()
        })
    }
    
    deinit {
        notificationTokens.forEach { $0.invalidate() }
    }
}

class ItemEntity: Object, Identifiable {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    
    override class func primaryKey() -> String? { "id" }
    override class func indexedProperties() -> [String] { ["id"] }
    
    private static var realm = try! Realm()
    
    static func setUp() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
            try! realm.write {
                print("### update \(Date())")
                realm.deleteAll()
                realm.add(createFixture(), update: .modified)
            }
        }
    }
    
    static func all() -> Results<ItemEntity> {
        realm.objects(ItemEntity.self)
    }
    
    private static func createFixture() -> [ItemEntity] {
        (0..<10)
            .map { _ in (0..<1000).randomElement()! }
            .map { number -> ItemEntity in
                let item = ItemEntity()
                item.id = "\(number)"
                item.name = "item\(number)"
                return item
            }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
