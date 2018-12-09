//
//  main.swift
//  SpaceBackground
//
//  Created by Nathan Severyns on 12/9/18.
//  Copyright © 2018 Nathan Severyns. All rights reserved.
//

import Foundation
import AppKit

let urlString : String = "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY"
let filePath : String = NSHomeDirectory() + "/Desktop/SpaceBackground/"
var isFinished : Bool = false

guard let url = URL(string: urlString) else {
    exit(EXIT_FAILURE)
}

struct Response: Codable {
    let copyright: String
    let date: String
    let explanation: String
    let hdurl: String
    let media_type: String
    let service_version: String
    let title: String
    let url: String
}

var responseData: Response? = nil

func saveFile(data: Data, name: String, attemptFix: Bool) -> Bool {
    let path = filePath + name
    let createSuccess = FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
    if (!createSuccess) {
        if (attemptFix) {
            createDirectory()
            if (saveFile(data: data, name: name, attemptFix: false)) {
                return true
            }
        }
        var response = "Unable to create a file at ";
        response.append(path)
        fatalError(response)
    }
    return true
}

func setBackground(name: String) {
    do {
        let path = filePath + name
        let url = NSURL.fileURL(withPath: path)
        let workspace = NSWorkspace.shared
        if let screen = NSScreen.main  {
            try workspace.setDesktopImageURL(url, for: screen, options: [:])
        }
    } catch {
        print(error)
    }
}

func createDirectory() {
    do {
        try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: false, attributes: nil)
    } catch let error as NSError {
        print(error.localizedDescription);
    }
}

func downloadImage(url: URL) {
    do {
        let split = url.absoluteString.split(separator: "/")
        let ending = split[split.count - 1]
        let data = try Data(contentsOf: url)
        if (saveFile(data: data, name: String(ending), attemptFix: true)) {
            setBackground(name: String(ending))
        }
        isFinished = true
    } catch let error {
        print("The url was not able to be read into Data")
        print(error.localizedDescription)
        exit(EXIT_FAILURE)
    }
}

func handleInitialData() {
    if responseData == nil {
        print("Response data does not exist.")
        exit(EXIT_FAILURE)
    }
    if let url = URL(string: (responseData?.hdurl)!) {
        downloadImage(url: url)
        //Handle
    }
}

URLSession.shared.dataTask(with: url) { (data, response, error) in
    if error != nil {
        print(error!.localizedDescription)
        exit(EXIT_FAILURE)
    }
    guard let data = data else { exit(EXIT_FAILURE) }
    do {
        responseData = try JSONDecoder().decode(Response.self, from: data)
        handleInitialData()
    } catch let jsonError {
        print("JSON ERROR: ")
        print(jsonError)
    }
}.resume()
while (!isFinished) {
    sleep(2)
}

