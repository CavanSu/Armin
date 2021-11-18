//
//  ArSessionDelegate.swift
//  Pods
//
//  Created by LYY on 2021/11/9.
//

import Foundation

/// ArSessionDelegator is weakly owned by Armin,which receives message from session tasks.
@objc class ArSessionDelegator: NSObject,
                                URLSessionTaskDelegate,
                                URLSessionDataDelegate,
                                URLSessionDownloadDelegate,
                                URLSessionStreamDelegate {
    private weak var armin: Armin?
    private weak var fileHandler: ArFileHandler?
    
    func setArmin(_ armin: Armin) {
        self.armin = armin
    }
    
    func setFileHandler(_ handler: ArFileHandler) {
        self.fileHandler = handler
    }
    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let armin = armin,
              let handler = armin.taskHandlers[task.taskIdentifier] else {
                  return
              }
        armin.removeTask(taskId: task.taskIdentifier)
        if let requestError = error,
           let fail = handler.requestFail {
            let arError = ArError.fail(requestError.localizedDescription,
                                       code: requestError._code)
            armin.request(error: arError,
                          of: handler.task.event,
                          with: handler.urlStr)
            fail(arError)
            return
        }
    }
    
    // MARK: - URLSessionDataDelegate
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        guard let handler = armin?.taskHandlers[dataTask.taskIdentifier],
              let progress = handler.progress else {
            return
        }
        let received = dataTask.countOfBytesReceived
        let all = dataTask.countOfBytesExpectedToReceive
        progress(Float(received) / Float(all))
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        armin.removeTask(taskId: task.taskIdentifier)
        
        guard let handler = armin?.taskHandlers[downloadTask.taskIdentifier],
              let downloadTask = handler.task as? ArDownloadTaskProtocol,
              let requestFail = handler.requestFail,
              let `success` = handler.success,
        let `fileHandler` = fileHandler else {
            return
        }
        var targetPath: String?
        do {
            // path handle
            targetPath = try fileHandler.generateFilePath(cover: downloadTask.object.cover,
                                                          fileLocation: location.path,
                                                          directoryPath: downloadTask.object.targetDirectory)
            // copy file and delete origin file
            try fileHandler.copyFile(filePath: location.path,
                                     targetPath: targetPath!)
        } catch {
            guard let arError = error as? ArError else {
                return
            }
            armin?.request(error: arError,
                           of: handler.task.event,
                           with:handler.urlStr)
            
            requestFail(arError)
            return
        }
        
        // handle success
        handler.responseQueue.async { [weak self] in
            self?.armin?.handleHttpSuccess(data: nil,
                                           location: targetPath,
                                           startTime: handler.startTime,
                                           from: handler.task,
                                           success: success)
        }
        
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let handler = armin?.taskHandlers[downloadTask.taskIdentifier],
              let progress = handler.progress else {
            return
        }
        progress(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
    }

    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didResumeAtOffset fileOffset: Int64,
                    expectedTotalBytes: Int64) {
        // 断点续传
        print(#function)
    }
}
