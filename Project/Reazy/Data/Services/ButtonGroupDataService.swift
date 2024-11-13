//
//  ButtonGroupDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/11/24.
//

import Foundation
import CoreData
import UIKit

class ButtonGroupDataService: ButtonGroupDataInterface {
    static let shared = ButtonGroupDataService()
    
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    private init() { }
    
    func loadButtonGroup(for pdfID: UUID) -> Result<[ButtonGroup], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<ButtonGroupData> = ButtonGroupData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            let fetchedGroups = try dataContext.fetch(fetchRequest)
            let buttonGroups = fetchedGroups.map { buttonGroupData -> ButtonGroup in
                
                let selectedLine = convertDataToCGRect(buttonGroupData.selectedLine)
                let buttonPosition = convertDataToCGRect(buttonGroupData.buttonPosition)
                
                return ButtonGroup(
                    id: buttonGroupData.id,
                    page: Int(buttonGroupData.page),
                    selectedLine: selectedLine,
                    buttonPosition: buttonPosition
                )
            }
            return .success(buttonGroups)
        } catch {
            return .failure(error)
        }
    }
    
    func saveButtonGroup(for pdfID: UUID, with buttonGroup: ButtonGroup) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchedRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchedRequest.predicate = NSPredicate(format: "id == %@", pdfID as CVarArg)
        
        do {
            if let paperData = try dataContext.fetch(fetchedRequest).first {
                let newButtonGroup = ButtonGroupData(context: dataContext)
                
                newButtonGroup.id = buttonGroup.id
                newButtonGroup.page = Int32(buttonGroup.page)
                newButtonGroup.selectedLine = convertCGRectToData(buttonGroup.selectedLine) ?? Data()
                newButtonGroup.buttonPosition = convertCGRectToData(buttonGroup.buttonPosition) ?? Data()
                
                newButtonGroup.paperData = paperData
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ButtonGroupData not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func deleteButtonGroup(for pdfID: UUID, id: UUID) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<ButtonGroupData> = ButtonGroupData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let buttonGroupToDelete = result.first {
                
                dataContext.delete(buttonGroupToDelete)
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "ButtonGroup not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    private func convertCGRectToData(_ rect: CGRect) -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: NSValue(cgRect: rect), requiringSecureCoding: true)
    }
    
    private func convertDataToCGRect(_ data: Data?) -> CGRect {
        guard let data = data,
              let rectValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data) else {
            return .zero
        }
        return rectValue.cgRectValue
    }
}
