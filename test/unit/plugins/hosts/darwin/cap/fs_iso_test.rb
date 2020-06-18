require "pathname"
require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/darwin/cap/fs_iso"

describe VagrantPlugins::HostDarwin::Cap::FsISO do
  include_context "unit"

  let(:subject){ VagrantPlugins::HostDarwin::Cap::FsISO }
  let(:env) { double("env") }

  describe ".isofs_available" do
    it "finds iso building utility when available" do
      expect(Vagrant::Util::Which).to receive(:which).and_return(true)
      expect(subject.isofs_available(env)).to eq(true)
    end

    it "does not find iso building utility when not available" do
      expect(Vagrant::Util::Which).to receive(:which).and_return(false)
      expect(subject.isofs_available(env)).to eq(false)
    end
  end

  describe ".create_iso" do
    let(:file_destination) { "/woo/out.iso" }

    before do 
      allow(file_destination).to receive(:nil?).and_return(false)
      allow(FileUtils).to receive(:mkdir_p)
    end

    it "builds an iso" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", file_destination: "/woo/out.iso")
      expect(output.to_s).to eq("/woo/out.iso")
    end

    it "builds an iso with volume_id" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-default-volume-name", "cidata", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", file_destination: "/woo/out.iso", volume_id: "cidata")
      expect(output.to_s).to eq("/woo/out.iso")
    end

    it "builds an iso given a file destination without an extension" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", file_destination: "/woo/out_dir")
      expect(output.to_s).to match(/\/woo\/out_dir\/[\w]{6}_vagrant.iso/)
    end

    it "builds an iso when no file destination is given" do
      allow(Tempfile).to receive(:new).and_return(file_destination)
      allow(file_destination).to receive(:path).and_return(file_destination)
      allow(file_destination).to receive(:delete)
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src")
      expect(output.to_s).to eq(file_destination)
    end

    it "raises an error if iso build failed" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).with(any_args).and_return(double(stdout: "nope", stderr: "nope", exit_code: 1))
      expect{ subject.create_iso(env, "/foo/src") }.to raise_error(Vagrant::Errors::ISOBuildFailed)
    end
  end
end
