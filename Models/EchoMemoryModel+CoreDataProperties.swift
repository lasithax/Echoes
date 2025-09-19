import Foundation
import CoreData

extension EchoMemoryModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EchoMemoryModel> {
        return NSFetchRequest<EchoMemoryModel>(entityName: "EchoMemoryModel")
    }

    @NSManaged public var title: String?

}

extension EchoMemoryModel : Identifiable {

}
