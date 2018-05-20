//
//  gasonwrapper_performanceTests.swift
//  gasonwrapperTests
//
//  Created by Benjamin on 20/5/2018.
//  Copyright © 2018 Benjamin. All rights reserved.
//

import XCTest
@testable import gasonwrapper

class gasonwrapper_performanceTests: XCTestCase {
    
    var d:[Data]?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let testURL = "https://raw.githubusercontent.com/Newbilius/big_json_import_demo/master/test_data/"
        //d = ["big.json","very_big.json","small.json"].flatMap({URL(string:testURL + $0)}).flatMap({try? Data(contentsOf: $0)})
        d = ["very_big.json"].compactMap({URL(string:testURL + $0)}).compactMap({try? Data(contentsOf: $0)})
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceBaseline(){
        guard let d = d else {return}
        self.measure {
            d.forEach({ (data) in
                do{
                    _ = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                }catch let e as NSError{
                    print("error: \(e.localizedDescription)")
                }
                
            })
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        guard let d = d else {return}
        
        self.measure {
            // Put the code you want to measure the time of here.
            d.forEach({ (data) in
                do{
                    _ = try JSON(data: data)
                }catch let e as NSError{
                    print("error: \(e.localizedDescription)")
                }
            })
        }
    }
    
}
