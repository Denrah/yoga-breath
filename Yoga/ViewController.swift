//
//  ViewController.swift
//  Yoga
//
//  Created by National Team on 17.10.2021.
//

import UIKit
import MessageUI

class ViewController: UIViewController {
  
  @IBOutlet private weak var bottomButton: UIButton!
  @IBOutlet private weak var breathContainerView: UIView!
  @IBOutlet private weak var breathStatusLabel: UILabel!
  @IBOutlet private weak var breathTimeLabel: UILabel!
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var placeholderView: UIStackView!
  
  private var breathRecognizer: BreathRecognizer?
  private var isBreathStart = false
  private var breathStartTime: TimeInterval = Date().timeIntervalSince1970
  private var breathTimer: Timer?
  private var hasFirstBreath = false
  private var breathTime = 0
  private var isRunning = false
  
  private var breathTimes: [Int] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    breathContainerView.isHidden = true
    tableView.dataSource = self
    tableView.rowHeight = 44
    tableView.estimatedRowHeight = 44
    tableView.alwaysBounceVertical = false
  }
  
  @IBAction private func bottomButtonTap(_ sender: Any) {
    if isRunning {
      stop()
      bottomButton.setTitle("Начать!", for: .normal)
    } else {
      start()
      bottomButton.setTitle("Завершить", for: .normal)
    }
  }
  
  private func start() {
    guard let breathRecognizer = try? BreathRecognizer(threshold: -17) else {
      let alert = UIAlertController(title: "Ошибка",
                                    message: "Не удалось начать отслеживание дыхания",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
      present(alert, animated: true, completion: nil)
      return
    }
    
    self.breathRecognizer = breathRecognizer
    breathRecognizer.onBreathChanged = { [weak self] isBreathing in
      self?.handleBreath(isBreathing: isBreathing)
    }
    breathTimes.removeAll()
    tableView.reloadData()
    breathTime = 0
    breathStatusLabel.text = "Дышите..."
    breathTimeLabel.text = "0"
    placeholderView.isHidden = true
    
    breathRecognizer.start()
    
    breathContainerView.isHidden = false
    breathTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      guard self?.hasFirstBreath == true else { return }
      self?.breathTime += 1
      self?.breathTimeLabel.text = "\(self?.breathTime ?? 0)"
    }
    
    isRunning = true
  }
  
  private func stop() {
    breathRecognizer = nil
    breathTimer?.invalidate()
    breathTimer = nil
    isRunning = false
    sendResults()
  }
  
  private func handleBreath(isBreathing: Bool) {
    guard isBreathing else { return }
    
    hasFirstBreath = true
    
    if isBreathStart {
      let currentTime = Date().timeIntervalSince1970
      let difference = Int(round(currentTime - breathStartTime))
      breathTimes.append(difference)
      isBreathStart = false
      breathStatusLabel.text = "Выдох"
      tableView.reloadData()
    } else {
      breathStartTime = Date().timeIntervalSince1970
      isBreathStart = true
      breathStatusLabel.text = "Вдох"
    }
    
    breathTime = 0
  }
  
  private func sendResults() {
    let alert = UIAlertController(title: "Поделиться результатом",
                                  message: "Отправить результат вашему тренеру?",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
      self?.sendEmail()
    }))
    alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))
    present(alert, animated: true, completion: nil)
  }
  
  private func sendEmail() {
    if MFMailComposeViewController.canSendMail() {
      let mail = MFMailComposeViewController()
      mail.mailComposeDelegate = self
      mail.setToRecipients(["arkady.trainer@yandex.ru"])
      
      var emailText = "<p>Аркадий, мои результаты занятия Йогой:</p><p>"
      
      breathTimes.enumerated().forEach { index, time in
        emailText.append("\(index + 1). Вдох-выдох – \(time) сек.<br>")
      }
      
      emailText += "</p>"
      
      mail.setMessageBody(emailText, isHTML: true)
      
      present(mail, animated: true)
    } else {
      let alert = UIAlertController(title: "Ошибка",
                                    message: "Не удалось отправить письмо. Возможно, на вашем устройстве не настроен почтовый аккаунт.",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
      present(alert, animated: true, completion: nil)
    }
  }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return breathTimes.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let index = indexPath.row
    guard index < breathTimes.count else { return UITableViewCell() }
    let cell = tableView.dequeueReusableCell(withIdentifier: "breathCell", for: indexPath)
    (cell.viewWithTag(1) as? UILabel)?.text = "\(index + 1)"
    (cell.viewWithTag(2) as? UILabel)?.text = "\(breathTimes[index]) сек."
    return cell
  }
}

// MARK: - MFMailComposeViewControllerDelegate

extension ViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController,
                             didFinishWith result: MFMailComposeResult, error: Error?) {
      controller.dismiss(animated: true)
  }
}
