//
//  ViewController.swift
//  MindfulMinutesStoryboard
//
//  Created by William Gillespie on 3/18/22.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore: HKHealthStore = HKHealthStore()
    
    let mindfulType: HKCategoryType? = HKObjectType.categoryType(forIdentifier: .mindfulSession)
    

    @IBOutlet weak var mindfulMinutesLabel: UILabel!
    @IBOutlet weak var totalMindfulMinutesLabel: UILabel!
    @IBAction func getMindfulMinutes(_ sender: Any) {
        self.retrieveMindfulMinutes()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activateHealthKit()
        self.retrieveMindfulMinutes()
    }
    
    func activateHealthKit() {
        // Define what HealthKit data we want to ask to read
        let typesToRead: Set<HKCategoryType> = Set([
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!
        ])
        
        // Define what HealthKit data we want to ask to write
        let typesToShare: Set<HKCategoryType> = Set([
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!
        ])
        
        // Prompt the User for HealthKit Authorization
        self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) -> Void in
            if !success{
                print("HealthKit Auth error\(String(describing: error))")
            }
        }
    }
    
    // Display a users mindful minutes for the last 24 hours
    func retrieveMindfulMinutes() {
        let sortDescriptor: NSSortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        
        let endDate: Date = Date()
        // one day ago = -1.0 * 60.0 * 60 * 24.0 seconds
        let startDate: Date = endDate.addingTimeInterval(-86400.0)
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query: HKSampleQuery = HKSampleQuery(sampleType: mindfulType!, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor], resultsHandler: updateMeditationTime)
        
        healthStore.execute(query)
    }
    
    // Sum the meditation time
    func updateMeditationTime(query: HKSampleQuery, results: [HKSample]?, error: Error?) {
        if error != nil {return}
        guard let mindfulnessSampleList: [HKSample] = results else {
            print("mindfulness sample list is not set")
            return
        }
        for i in 0..<results!.count {
            guard let categorySample: HKCategorySample = results![i] as? HKCategorySample else {
                print("item in return list was not of type HKCategorySample")
                return;
            }
            let startDate: Date = categorySample.startDate
            let endDate: Date = categorySample.endDate
            let sampleType: HKSampleType = categorySample.sampleType
            let sampleMetadata: [String : Any]? = categorySample.metadata
            let sampleDescription: String = categorySample.description
            let sampleHasUndeterminedDuration: Bool = categorySample.hasUndeterminedDuration
            print("category sample #\(i) values: \n\tsample.startDate: \(startDate),\n\tsample.endDate: \(endDate),\n\tsample.sampleType: \(sampleType), \n\tsample.sampleMetadata: \(String(describing: sampleMetadata)),\n\tsample.description:\(sampleDescription),\n\tsample.hasUndeterminedDuration: \(sampleHasUndeterminedDuration)")
        }
        
        print(mindfulnessSampleList)
        
        let totalMeditationTime = results?.map(calculateTotalTime).reduce(0, {$0 + $1}) ?? 0

        print("\n Total: \(totalMeditationTime)")
        renderMeditationMinuteText(totalMeditationSeconds: totalMeditationTime)
    }
    
    func calculateTotalTime(sample: HKSample) -> TimeInterval {
        let totalTime: TimeInterval = sample.endDate.timeIntervalSince(sample.startDate)
//        let wasUserEntered: Bool = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
        return totalTime
    }
    
    // Update the Meditation Minute Label
    func renderMeditationMinuteText(totalMeditationSeconds: Double) {
        let minutes = Int(totalMeditationSeconds / 60)
        let minutesText = minutes == 1 ? "minute" : "minutes"
        let labelText = "\(minutes) Mindful \(minutesText) in the last 24 hours"
        DispatchQueue.main.async {
            self.totalMindfulMinutesLabel.text = labelText
        }
    }

}

