class UpdateSignatureDetection < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Define transaction backend.',
      name: '1000_signature_detection',
      area: 'Transaction::Backend',
      description: 'Define the transaction backend to detect customers signature in email.',
      options: {},
      state: 'Transaction::SignatureDetection',
      frontend: false
    )
  end
end
