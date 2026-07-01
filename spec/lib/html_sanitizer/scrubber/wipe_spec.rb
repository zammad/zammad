# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Wipe do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) do
      # export with extra options to avoid html indentation
      fragment.scrub!(scrubber)
        .to_html save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^ Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    let(:fragment) { Loofah.html5_fragment(input) }

    context 'when has not allowed tag' do
      let(:input)  { '<not-allowed><b>asd</b></not-allowed>' }
      let(:target) { '<b>asd</b>' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed tag in not allowed' do
      let(:input)  { '<not-allowed><not-allowed>asd</not-allowed></not-allowed>' }
      let(:target) { 'asd' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed tag inside of an allowed tag' do
      let(:input)  { '<div><not-allowed></not-allowed></div>' }
      let(:target) { '<div></div>' }

      it { is_expected.to eq target }
    end

    context 'when insecure source' do
      let(:input)  { '<img src="http://example.org/image.jpg">' }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed classes' do
      let(:input)  { '<div class="to-be-removed js-signatureMarker">test</div>' }
      let(:target) { '<div class="js-signatureMarker">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has width and height attributes' do
      let(:input)  { '<img width="100px" height="100px" other="true">' }
      let(:target) { '<img style="width:100px;height:100px;">' }

      it { is_expected.to eq target }
    end

    context 'when has width and max-width attributes' do
      let(:input)  { '<img width="100px" style="max-width: 600px">' }
      let(:target) { '<img style="max-width: 600px;width:100px;">' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed attributes' do
      let(:input)  { '<div width="100px" style="color:#ff0000" other="true">test</div>' }
      let(:target) { '<div style="color:#ff0000;">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has style' do
      let(:input)  { '<div style="color:white">test</div><div style="color:#ff0000;">test</div>' }
      let(:target) { '<div>test</div><div style="color:#ff0000;">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has executeable link' do
      let(:input)  { '<img style="width:100%" src="javascript:alert()">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when href contains javascript: scheme' do
      let(:input)  { '<a href="javascript:alert()">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when href contains data: scheme' do
      let(:input)  { '<a href="data:text/html,<h1>XSS</h1>">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when href contains data: scheme with javascript' do
      let(:input)  { '<a href="data:text/javascript,alert(1)">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when href contains data: scheme uppercased' do
      let(:input)  { '<a href="DATA:text/html,<b>test</b>">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when style contains data: scheme' do
      let(:input)  { '<a style="data:text/html,something">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when has an image with a proper link' do
      let(:input)  { '<img style="width:100%" src="https://zammad.org/dummy.png">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses http: scheme without slashes' do
      let(:input)  { '<img src="http:attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses https: scheme without slashes' do
      let(:input)  { '<img src="https:attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when srcset uses http: scheme without slashes' do
      let(:input)  { '<img srcset="http:attacker.example/pixel.gif 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when has a remote srcset without src' do
      let(:input)  { '<img srcset="https://tracking.example.com/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when has a remote srcset with a local src' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="https://tracking.example.com/pixel.gif 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1">' } # srcset should be stripped

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when srcset has only safe sources' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x, /api/v1/attachments/2 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x, /api/v1/attachments/2 2x">' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset has a mix of safe and unsafe sources' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x, https://tracking.example.com/pixel.gif 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x">' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when srcset contains a data: URL with a comma in it' do
      let(:input)  { '<img srcset="data:image/png,abc 1x">' }
      let(:target) { '<img srcset="data:image/png,abc 1x">' }

      it { is_expected.to eq target }
    end

    context 'when srcset has a javascript: URL' do
      let(:input)  { '<img srcset="javascript:alert() 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset candidates are separated by multiple commas with a remote entry' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x,, https://remote.example.com/track.gif 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x">' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src is present but empty' do
      let(:input)  { '<img src="">' }
      let(:target) { '<img src="">' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset is present but empty' do
      let(:input)  { '<img srcset="">' }
      let(:target) { '<img srcset="">' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to signout endpoint' do
      let(:input)  { "<img src='/api/v1/signout'>" }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to sessions switch' do
      let(:input)  { "<img src='/api/v1/sessions/switch/5'>" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when src points to sessions switch back' do
      let(:input)  { "<img src='/api/v1/sessions/switch_back'>" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when src points to auto wizard' do
      let(:input)  { "<img src='/api/v1/getting_started/auto_wizard/token123'>" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when srcset contains an api endpoint candidate' do
      let(:input)  { '<img srcset="/api/v1/signout 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset contains an interior-traversal api path' do
      let(:input)  { '<img srcset="/api/v1/attachments/../signout 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src contains a double-encoded traversal api path' do
      let(:input)  { '<img src="/api/v1/attachments/%252e%252e/signout">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is a safe path-absolute URL' do
      let(:input) { "<img src='/assets/images/logo.png'>" }

      it { is_expected.to include('/assets/images/logo.png') }
    end

    context 'when src is a safe relative URL without leading slash' do
      let(:input) { "<img src='images/logo.png'>" }

      it { is_expected.to include('images/logo.png') }
    end

    context 'when src points to allowed content path (ticket attachment)' do
      let(:input) { "<img src='/api/v1/ticket_attachment/1/2/3'>" }

      it { is_expected.to include('/api/v1/ticket_attachment/1/2/3') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to allowed content path (attachment store)' do
      let(:input) { "<img src='/api/v1/attachments/1'>" }

      it { is_expected.to include('/api/v1/attachments/1') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to user avatar' do
      let(:input) { "<img src='/users/image/abc123'>" }

      it { is_expected.to include('/users/image/abc123') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is a relative api path without leading slash' do
      let(:input)  { "<img src='api/v1/signout'>" }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is a relative api path with parent dir' do
      let(:input)  { "<img src='../api/v1/signout'>" }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is attachment store without trailing path' do
      let(:input) { "<img src='/api/v1/attachments'>" }

      it { is_expected.to include('/api/v1/attachments') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is authorize (not api/auth)' do
      let(:input) { "<img src='/authorize'>" }

      it { is_expected.to include('/authorize') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end
  end

  describe '#unsafe_api_path?' do
    subject(:unsafe) { scrubber.send(:unsafe_api_path?, path) }

    let(:scrubber) { described_class.new }

    {
      # allowlisted api paths
      '/api/v1/attachments/1'                               => false,
      '/api/v1/attachments'                                 => false,
      '/api/v1/ticket_attachment/1/2/3?view=inline'         => false,
      'api/v1/attachments/1'                                => false,

      # blocked api paths
      '/api/v1/attachments_evil'                            => true,
      '/api/v1/ticket_attachment_upload_clone_by_article/1' => true,
      '/api/v1/signout'                                     => true,
      '../api/v1/signout'                                   => true,
      '../api/v1/attachments/'                              => true,
      '../api/v1/attachments/1'                             => true,

      # interior traversal bypass (literal, double-encoded, and backslash separator variants)
      '/api/v1/attachments/../signout'                      => true,
      '/api/v1/attachments/./signout'                       => true,
      '/api/v1/ticket_attachment/../signout'                => true,
      '/api/v1/attachments/%2e%2e/signout'                  => true,
      '/api/v1/attachments/..\signout'                      => true,

      # non-api paths
      '/users/image/abc123'                                 => false,
      '/assets/images/logo.png'                             => false,
    }.each do |test_path, expected_unsafe|
      context "with #{test_path.inspect}" do
        let(:path) { test_path }

        it "is #{expected_unsafe ? 'unsafe' : 'safe'}" do
          expect(unsafe).to be(expected_unsafe)
        end
      end
    end
  end
end
