require_relative './spec_helper'

describe("GeoEngineer::Resource") do
  describe '#remote_resource' do
    class GeoEngineer::RemoteResources < GeoEngineer::Resource
      def self._fetch_remote_resources
        [{ _geo_id: "geo_id1" }, { _geo_id: "geo_id2" }, { _geo_id: "geo_id2" }]
      end
    end

    it 'should return a list of resources' do
      rem_res = GeoEngineer::RemoteResources.new('rem', 'id') {
        _geo_id "geo_id1"
      }

      norem_res = GeoEngineer::RemoteResources.new('rem', 'id') {
        _geo_id "geo_id3"
      }

      expect(rem_res.remote_resource.nil?).to eq false
      expect(norem_res.remote_resource.nil?).to eq true
    end

    it 'should error if you match more than one' do
      rem = GeoEngineer::RemoteResources.new('rem', 'id') {
        _geo_id "geo_id2"
      }
      expect { rem.remote_resource }.to raise_error(StandardError)
    end
  end

  describe '#to_terraform_json' do
    it 'should return _terraform_id as primary' do
      class GeoEngineer::TFJSON < GeoEngineer::Resource
        after :initialize, -> { _terraform_id "tid" }
      end

      res = GeoEngineer::TFJSON.new('tf_json', 'ididid') {
        blue "TRUE"
        tags {
          not_blue "FALSE"
        }
      }

      tfjson = res.to_terraform_json

      expect(tfjson['blue']).to eq 'TRUE'
      expect(tfjson['tags'][0]['not_blue']).to eq 'FALSE'
    end
  end

  describe '#to_terraform_state' do
    it 'should return _terraform_id as primary' do
      class GeoEngineer::TFState < GeoEngineer::Resource
        after :initialize, -> { _terraform_id "tid" }
      end

      tfs = GeoEngineer::TFState.new('tf_state', 'asd').to_terraform_state
      expect(tfs[:type]).to eq 'tf_state'
      expect(tfs[:primary][:id]).to eq 'tid'
    end

    it 'should return _terraform_id as primary' do
      class GeoEngineer::TFState < GeoEngineer::Resource
        after :initialize, -> { _terraform_id "tid" }
      end

      tfs = GeoEngineer::TFState.new('tf_state', 'asd').to_terraform_state
      expect(tfs[:type]).to eq 'tf_state'
      expect(tfs[:primary][:id]).to eq 'tid'
    end
  end

  describe '#fetch_remote_resources' do
    it 'should return a list of resources' do
      class GeoEngineer::FetchableResources < GeoEngineer::Resource
        def self._fetch_remote_resources
          [{ _geo_id: "geoid" }]
        end
      end

      resources = GeoEngineer::FetchableResources.fetch_remote_resources()
      expect(resources.length).to eq 1
      expect(resources[0]._geo_id).to eq "geoid"
    end
  end

  describe '#validate_required_subresource' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasSRAttrResource < GeoEngineer::Resource
        validate -> { validate_required_subresource :tags }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {}
      with_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {
        tags {
          blue "True"
        }
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_subresource_required_attributes' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasSRAttrResource < GeoEngineer::Resource
        validate -> { validate_subresource_required_attributes :tags, [:blue] }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {
        tags {}
      }
      with_blue = GeoEngineer::HasSRAttrResource.new('has_attr', 'id') {
        tags {
          blue "True"
        }
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_required_attributes' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasAttrResource < GeoEngineer::Resource
        validate -> { validate_required_attributes [:blue] }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasAttrResource.new('has_attr', 'id')
      with_blue = GeoEngineer::HasAttrResource.new('has_attr', 'id') {
        blue "True"
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe '#validate_has_tag' do
    it 'should return errors if it does not have a tag' do
      class GeoEngineer::HasTagResource < GeoEngineer::Resource
        validate -> { validate_has_tag :blue }
        after :initialize, -> { _terraform_id "tid'" }
      end
      not_blue = GeoEngineer::HasTagResource.new('has_tag', 'id')
      with_blue = GeoEngineer::HasTagResource.new('has_tag', 'id') {
        tags {
          blue "True"
        }
      }
      expect(not_blue.errors.length).to eq 1
      expect(with_blue.errors.length).to eq 0
    end
  end

  describe 'class method' do
    describe('#type_from_class_name') do
      it 'should return resource' do
        expect(GeoEngineer::Resource.type_from_class_name).to eq 'resource'
      end

      it 'should remove module' do
        class GeoEngineer::ResourceType < GeoEngineer::Resource
        end
        expect(GeoEngineer::ResourceType.type_from_class_name).to eq 'resource_type'
      end
    end
  end
end
