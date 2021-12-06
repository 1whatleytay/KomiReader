import SQLite
import Foundation

class Cache : ObservableObject {
    let db: Connection
    
    let chaptersTable = Table("chapters")
    
    let numberExpression = Expression<Int64>("number")
    let nameExpression = Expression<String>("name")
    let linkExpression = Expression<String>("link")
    
    let imagesTable = Table("images")
    
    // numberExpression
    let imagePositionExpression = Expression<Int64>("position")
    let imageDataExpression = Expression<Data>("data")
    
    @Published
    /*private(set)*/ var chapters = [Chapter]()
    
    @Published
    /*private(set)*/ var downloaded = Set<Int>()
    
    func dropChapters() throws {
        try db.run(chaptersTable.drop())
        
        chapters.removeAll()
    }
    
    func createChapters() throws {
        try db.run(chaptersTable.create(ifNotExists: true) {
            t in
            
            t.column(numberExpression, primaryKey: true)
            t.column(nameExpression)
            t.column(linkExpression, unique: true)
        })
    }
    
    func add(chapter: Chapter) throws {
        try db.run(chaptersTable.insert(
            numberExpression <- Int64(chapter.chapter),
            nameExpression <- chapter.name,
            linkExpression <- chapter.link
        ))
        
        chapters.append(chapter)
    }
    
    func add(chapters: [Chapter]) throws {
        do {
            try db.transaction {
                for chapter in chapters {
                    try db.run(chaptersTable.upsert(
                        numberExpression <- Int64(chapter.chapter),
                        nameExpression <- chapter.name,
                        linkExpression <- chapter.link,
                        onConflictOf: numberExpression
                    ))
                }
            }
        } catch let Result.error(message, code, statement) {
            print("\(message), code: \(code), statement: \(statement?.description ?? "nil")")
        }
        
        self.chapters = chapters
    }
    
    
    func dropImages() throws {
        try db.run(imagesTable.drop())
        
        downloaded.removeAll()
    }
    
    func createImages() throws {
        try db.run(imagesTable.create(ifNotExists: true) {
            t in
            
            t.column(numberExpression)
            t.column(imagePositionExpression)
            t.column(imageDataExpression)
        })
        
        try db.run(imagesTable.createIndex(numberExpression, ifNotExists: true))
    }
    
    func addImages(number: Int, images: [Data]) throws {
        try db.transaction {
            for (i, image) in images.enumerated() {
                try db.run(imagesTable.insert(
                    numberExpression <- Int64(number),
                    imagePositionExpression <- Int64(i),
                    imageDataExpression <- image
                ))
            }
        }
        
        downloaded.insert(number)
    }
    
    func getImages(number: Int) throws -> [Data]? {
        var result = [Data]()
        
        for image in try db.prepare(imagesTable
                    .select(imageDataExpression)
                    .filter(numberExpression == Int64(number))
                    .order(imagePositionExpression.asc)
        ) {
            result.append(image[imageDataExpression])
        }
        
        return result.isEmpty ? nil : result
    }
    
    init() throws {
        //"cache.sqlite3"
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard var url = urls.first else { throw NSError() }
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        url.appendPathComponent("cache.sqlite3")
        
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        
        self.db = try Connection(url.path)
        
        try createChapters()
        try createImages()
    
        for chapter in try db.prepare(chaptersTable) {
            self.chapters.append(Chapter(
                link: chapter[linkExpression],
                name: chapter[nameExpression],
                chapter: Int(chapter[numberExpression])
            ))
        }
        
        for row in try db.prepare(imagesTable.select(distinct: numberExpression)) {
            downloaded.insert(Int(row[numberExpression]))
        }
    }
}
