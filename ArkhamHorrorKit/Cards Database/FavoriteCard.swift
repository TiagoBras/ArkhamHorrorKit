import GRDB

final class FavoriteCard: Record {
    var cardId: Int
    
    override class var databaseTableName: String {
        return "FavoriteCard"
    }
    
    init(cardId: Int) {
        self.cardId = cardId
        
        super.init()
    }
    
    required init(row: Row) {
        cardId = row[ColumnName.cardId.rawValue]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[ColumnName.cardId.rawValue] = cardId
    }
    
    enum ColumnName: String {
        case cardId = "card_id"
    }
}
