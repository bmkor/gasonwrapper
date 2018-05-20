//
//  gasonwrapper_parsingTests.swift
//  gasonwrapperTests
//
//  Created by Benjamin on 20/5/2018.
//  Copyright © 2018 Benjamin. All rights reserved.
//

import XCTest
@testable import gasonwrapper

class gasonwrapper_parsingTests: XCTestCase {
    var g:JSON?
    var pass:[URL]?
    var fail:[URL]?
    var indetermine:[URL]?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if let url = Bundle(for:type(of: self)).url(forResource: "jsonlist", withExtension: "json"), let casepaths = try? Data(contentsOf: url){
            g = try? JSON(data: casepaths)
            
            if let site = g?["site"]?.string{
                pass = (g?["pass"]?.array?.compactMap({$0.string}).map({site + $0}).compactMap({URL(string:$0)}))
                fail = (g?["fail"]?.array?.compactMap({$0.string}).map({site + $0}).compactMap({URL(string:$0)}))
                indetermine = (g?["indetermine"]?.array?.compactMap({$0.string}).map({site + $0}).compactMap({URL(string:$0)}))
            }
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFail(){
        var expectations:[XCTestExpectation] = []
        var dataTasks:[URLSessionDataTask] = []
        var correctCnt:Int = 0
        var passed:[String] = []
        var failed:[String:String] = [:]
        
        XCTAssertNotNil(fail)
        fail?.forEach({ (url) in
            let expectation = self.expectation(description: url.absoluteString)
            let dt = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                if let data = data{
                    do {
//                        _ = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                        _ = try JSON(data: data)
                        passed.append(url.lastPathComponent)
                    }catch let e as NSError{
                        correctCnt += 1
                        failed[url.lastPathComponent] = e.localizedDescription
                    }
                    expectation.fulfill()
                }
            })
            expectations.append(expectation)
            dataTasks.append(dt)
        })
        dataTasks.forEach({$0.resume()})
        self.wait(for: expectations, timeout: 1000)
        passed.forEach { (s) in
            print("passed: \(s)")
        }
        print("\n fail case: \n \t correct count: \(correctCnt). \t Total count: \(fail?.count ?? 0) \n" )
        
        XCTAssert(fail!.count > 0)
        
        XCTAssert(Float(correctCnt)/Float(fail!.count) >= 0.7)
        
        
    }
    
    func testPass(){
        var expectations:[XCTestExpectation] = []
        var dataTasks:[URLSessionDataTask] = []
        var correctCnt:Int = 0
        var passed:[String] = []
        var failed:[String:String] = [:]
        
        XCTAssertNotNil(pass)
        pass?.forEach({ (url) in
            let expectation = self.expectation(description: url.absoluteString)
            let dt = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                if let data = data{
                    do {
                        _ = try JSON(data: data)
//                        _ = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                        passed.append(url.lastPathComponent)
                        correctCnt += 1
                    }catch let e as NSError{
                        failed[url.lastPathComponent] = e.localizedDescription
                    }
                    expectation.fulfill()
                }
            })
            expectations.append(expectation)
            dataTasks.append(dt)
        })
        dataTasks.forEach({$0.resume()})
        self.wait(for: expectations, timeout: 1000)
        failed.forEach { (k, v) in
            print("failed: \(k), \t reason: \(v)")
        }
        print("\n pass case: \n \t correct count: \(correctCnt). \t Total count: \(pass?.count ?? 0) \n" )
        XCTAssert(pass!.count > 0)
        XCTAssert(Float(correctCnt)/Float(pass!.count) >= 0.8)
    }
    
    func testIndetermine(){
        var expectations:[XCTestExpectation] = []
        var dataTasks:[URLSessionDataTask] = []
        var passed:[String] = []
        var failed:[String:String] = [:]
        
        XCTAssertNotNil(indetermine)
        indetermine?.forEach({ (url) in
            let expectation = self.expectation(description: url.absoluteString)
            let dt = URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                if let data = data{
                    do {
                        _ = try JSON(data: data)
//                        _ = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                        passed.append(url.lastPathComponent)
                        
                    }catch let e as NSError{
                        failed[url.lastPathComponent] = e.localizedDescription
                    }
                    expectation.fulfill()
                }
            })
            expectations.append(expectation)
            dataTasks.append(dt)
        })
        dataTasks.forEach({$0.resume()})
        self.wait(for: expectations, timeout: 1000)
        
        passed.forEach { (s) in
            print("passed: \(s)")
        }
        
        failed.forEach { (k, v) in
            print("failed: \(k), \t reason: \(v)")
        }
        print("\n indetermine case: \n \t passed count: \(passed.count), failed count: \(failed.count).  \t Total count: \(indetermine?.count ?? 0) \n" )
    }
    
}
